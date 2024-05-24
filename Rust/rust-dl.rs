use std::fs;
use std::io::{self, Write};

use reqwest::blocking::Client;
use scraper::{Html, Selector};

fn prompt(message: &str) -> String {
    print!("{}", message);
    io::stdout().flush().unwrap();
    let mut input = String::new();
    io::stdin().read_line(&mut input).unwrap();
    input.trim().to_string()
}

fn get_page(url: &str) -> Result<String, reqwest::Error> {
    let client = Client::new();
    let res = client.get(url).send()?;
    if !res.status().is_success() {
        return Err(reqwest::Error::new(reqwest::StatusCode::INTERNAL_SERVER_ERROR, "HTTP error"));
    }
    let body = res.text()?;
    Ok(body)
}

fn get_image_url(page_source: &str) -> Result<String, &'static str> {
    let fragment = Html::parse_document(page_source);
    let selector = Selector::parse(r#"meta[property="og:image"]"#).unwrap();
    let image_link = fragment.select(&selector).next().ok_or("Image URL not found")?;
    let image_link = image_link.value().attr("content").ok_or("Image URL not found")?;
    Ok(image_link.to_string())
}

fn get_image(image_link: &str, output_path: &str, filename: &str) -> Result<(), Box<dyn std::error::Error>> {
    let response = reqwest::blocking::get(image_link)?;
    if !response.status().is_success() {
        return Err(Box::new(reqwest::Error::new(reqwest::StatusCode::INTERNAL_SERVER_ERROR, "HTTP error")));
    }
    let bytes = response.bytes()?;
    let path = if output_path.ends_with('/') {
        format!("{}{}.png", output_path, filename)
    } else {
        format!("{}/{}.png", output_path, filename)
    };
    fs::write(&path, bytes)?;
    println!("Image saved successfully at {}", path);
    Ok(())
}

fn main() {
    let url = prompt("Enter URL of the image page: ");
    let page_source = match get_page(&url) {
        Ok(body) => body,
        Err(err) => {
            eprintln!("Error fetching the page: {:?}", err);
            return;
        }
    };
    let image_link = match get_image_url(&page_source) {
        Ok(link) => link,
        Err(err) => {
            eprintln!("Error fetching the image URL: {:?}", err);
            return;
        }
    };
    let output_path = prompt("Enter desired folder path: ");
    let filename = "output".to_string(); // Change this to your desired output filename
    match get_image(&image_link, &output_path, &filename) {
        Ok(_) => {}
        Err(err) => eprintln!("Error downloading the image: {:?}", err),
    };
}
