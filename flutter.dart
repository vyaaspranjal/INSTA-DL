import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _urlController = TextEditingController();
  final _outputPathController = TextEditingController();
  final _filenameController = TextEditingController();

  Future<void> _downloadImage() async {
    String url = _urlController.text;
    String outputPath = _outputPathController.text;
    String filename = _filenameController.text;

    try {
      http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('HTTP error! Status: ${response.statusCode}');
      }
      String pageSource = utf8.decode(response.bodyBytes);
      String imageUrl = _getImageUrl(pageSource);

      response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP error! Status: ${response.statusCode}');
      }
      List<int> bytes = response.bodyBytes;

      Directory appDocDir = await getApplicationDocumentsDirectory();
      String appDocPath = appDocDir.path;
      String imagePath = '$appDocPath/$outputPath/$filename.png';

      File imageFile = File(imagePath);
      await imageFile.writeAsBytes(bytes);
      print('Image saved successfully at $imagePath');
    } catch (error) {
      print('An error occurred: $error');
    }
  }

  String _getImageUrl(String pageSource) {
    String before = '<meta property="og:image" content="';
    int pos = pageSource.indexOf(before);
    if (pos == -1) {
      throw Exception('Image URL not found');
    }
    int start = pos + before.length;
    int end = pageSource.indexOf('"', start);
    if (end == -1) {
      throw Exception('Image URL not found');
    }
    return pageSource.substring(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Downloader'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL of the image page',
              ),
            ),
            SizedBox(height: 10.0),
            TextField(
              controller: _outputPathController,
              decoration: InputDecoration(
                labelText: 'Desired folder path',
              ),
            ),
            SizedBox(height: 10.0),
            TextField(
              controller: _filenameController,
              decoration: InputDecoration(
                labelText: 'Output filename',
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _downloadImage,
              child: Text('Download Image'),
            ),
          ],
        ),
      ),
    );
  }
}
