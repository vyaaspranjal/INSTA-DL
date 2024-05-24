const fetch = require('node-fetch');
const { URLSearchParams } = require('url');
const readline = require('readline');
const fs = require('fs');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function promptUrl() {
  return new Promise((resolve, reject) => {
    rl.question('Enter URL of the image page: ', (url) => {
      resolve(url);
    });
  });
}

function promptOutputPath() {
  return new Promise((resolve, reject) => {
    rl.question('Enter desired folder path: ', (path) => {
      resolve(path);
    });
  });
}

async function getPage(url) {
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return await response.text();
    } catch (error) {
        console.error('Error fetching the page:', error);
        throw error;
    }
}

async function getImageUrl(page_source) {
    const before = '<meta property="og:image" content="';
    const pos = page_source.indexOf(before);
    if (pos !== -1) {
        let image_link = '';
        let i = pos + before.length;
        while (page_source[i] !== '"') {
            image_link += page_source[i];
            i++;
        }
        return image_link;
    } else {
        throw new Error('Image URL not found');
    }
}

async function getImage(image_link, outputPath, filename) {
    try {
        const response = await fetch(image_link);
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        const buffer = await response.buffer();
        const path = outputPath.endsWith('/') ? outputPath : outputPath + '/';
        const TOTAL_PATH = `${path}${filename}.png`;
        fs.writeFileSync(TOTAL_PATH, buffer);
        console.log(`Image saved successfully at ${TOTAL_PATH}`);
    } catch (error) {
        console.error('Error downloading the image:', error);
        throw error;
    }
}

async function main() {
    try {
        const url = await promptUrl();
        const page_source = await getPage(url);
        const image_link = await getImageUrl(page_source);
        const outputPath = await promptOutputPath();
        const filename = 'output'; // Change this to your desired output filename
        await getImage(image_link, outputPath, filename);
        rl.close();
    } catch (error) {
        console.error('An error occurred:', error);
        rl.close();
    }
}

main();
