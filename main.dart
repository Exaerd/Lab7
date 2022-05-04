import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Лента новостей КубГАУ';
    return const MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
    );
  }
}


class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}


Future<List<KubsauNews>> fNews(http.Client client) async {
  HttpOverrides.global = MyHttpOverrides();
  final response = await client.get(Uri.parse('https://old.kubsau.ru/api/getNews.php?key=6df2f5d38d4e16b5a923a6d4873e2ee295d0ac90'));
  return compute(pNews, response.body);
}

List<KubsauNews> pNews(String responseBody) {
  responseBody = Bidi.stripHtmlIfNeeded(responseBody);
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<KubsauNews>((json) => KubsauNews.fromJson(json)).toList();
}


class KubsauNews {
  final String ID;
  final String ACTIVE_FROM;
  final String TITLE;
  final String PREVIEW_TEXT;
  final String PREVIEW_PICTURE_SRC;
  final String DETAIL_PAGE_URL;
  final String DETAIL_TEXT;
  final String LAST_MODIFIED;

  const KubsauNews({
    required this.ID,
    required this.ACTIVE_FROM,
    required this.TITLE,
    required this.PREVIEW_TEXT,
    required this.PREVIEW_PICTURE_SRC,
    required this.DETAIL_PAGE_URL,
    required this.DETAIL_TEXT,
    required this.LAST_MODIFIED,
  });

  factory KubsauNews.fromJson(Map<String, dynamic> json) {
    return KubsauNews(
      ID: json['ID'] as String,
      ACTIVE_FROM: json['ACTIVE_FROM'] as String,
      TITLE: json['TITLE'] as String,
      PREVIEW_TEXT: json['PREVIEW_TEXT'] as String,
      PREVIEW_PICTURE_SRC: json['PREVIEW_PICTURE_SRC'] as String,
      DETAIL_PAGE_URL: json['DETAIL_PAGE_URL'] as String,
      DETAIL_TEXT: json['DETAIL_TEXT'] as String,
      LAST_MODIFIED: json['LAST_MODIFIED'] as String,
    );
  }
}


class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.green
      ),
      body: FutureBuilder<List<KubsauNews>>(
        future: fNews(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Ошибка запроса!'),
            );
          } else if (snapshot.hasData) {
            return WatchKubsauNews(newsRoster: snapshot.data!);
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}


class WatchKubsauNews extends StatelessWidget {
  const WatchKubsauNews({Key? key, required this.newsRoster}) : super(key: key);

  final List<KubsauNews> newsRoster;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: newsRoster.length,
      itemBuilder: (context, index) {
        return Card(
          child: Card(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(newsRoster[index].PREVIEW_PICTURE_SRC),
                Text(newsRoster[index].ACTIVE_FROM),
                Text(newsRoster[index].TITLE),
                Text(newsRoster[index].PREVIEW_TEXT),
              ],
            ),
            margin: const EdgeInsets.all(17),
          ),
        );
      },
    );
  }
}