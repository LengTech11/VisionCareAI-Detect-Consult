import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:disease_detector_app/utils/logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

class PDFScreen extends StatefulWidget {
  const PDFScreen({
    super.key,
    this.path,
    required this.url,
    required this.title,
  });
  final String url, title;
  final String? path;

  @override
  PDFScreenState createState() => PDFScreenState();
}

class PDFScreenState extends State<PDFScreen> with WidgetsBindingObserver {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  String? pathPDF;
  String landscapePathPdf = "";
  String remotePDFpath = "";
  String corruptedPathPDF = "";

  @override
  void initState() {
    super.initState();
    List<String> parts = widget.url.split('/');
    String fileName = parts.last;

    downloadAndSavePdf(widget.url, fileName).then((f) {
      setState(() {
        pathPDF = f.path;
      });
    });
  }

  Future<File> downloadAndSavePdf(String url, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      printMe(directory.path);
      printMe(url);
      if (await file.exists()) {
        return file;
      }

      if (kDebugMode) {
        print('URL: ${widget.url}');
      }
      final response = await Dio()
          .download(widget.url, filePath); // Use url instead of widget.url
      if (response.statusCode == 200) {
        return file;
      } else {
        throw Exception('Error downloading PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Document")),
      body: Stack(
        children: <Widget>[
          pathPDF == null
              ? const Center(child: CircularProgressIndicator())
              : PDFView(
                  filePath: pathPDF,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: false,
                  pageFling: true,
                  pageSnap: true,
                  defaultPage: currentPage ?? 1,
                  fitPolicy: FitPolicy.WIDTH,
                  preventLinkNavigation:
                      false, // if set to true the link is handled in flutter
                  onRender: (pages) {
                    setState(() {
                      pages = pages;
                      isReady = true;
                    });
                  },
                  onError: (error) {
                    setState(() {
                      errorMessage = error.toString();
                    });
                    printMe(error.toString());
                  },
                  onPageError: (page, error) {
                    setState(() {
                      errorMessage = '$page: ${error.toString()}';
                    });
                    printMe('$page: ${error.toString()}');
                  },
                  onViewCreated: (PDFViewController pdfViewController) {
                    _controller.complete(pdfViewController);
                  },
                  onLinkHandler: (String? uri) {
                    printMe('goto uri: $uri');
                  },
                  onPageChanged: (int? page, int? total) {
                    printMe('page change: $page/$total');
                    setState(() {
                      currentPage = page;
                    });
                  },
                ),
          errorMessage.isEmpty
              ? !isReady
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Container()
              : Center(
                  child: Text(errorMessage),
                )
        ],
      ),
      floatingActionButton: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return FloatingActionButton.extended(
              label: const Icon(Icons.keyboard_arrow_up),
              onPressed: () async {
                await snapshot.data!.setPage(0);
              },
            );
          }

          return Container();
        },
      ),
    );
  }
}
