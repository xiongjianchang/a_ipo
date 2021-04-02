import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'impl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '打新日历',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WebViewController webViewController;
  DateTime lastClickTime;

  @override
  Widget build(BuildContext context) {
    WebViewCreatedCallback onWebViewCreated = (WebViewController controller) {
      webViewController = controller;
    };
    NavigationDelegate navigationDelegate = (NavigationRequest request) {
      //路由拦截
      if (request.url.startsWith('http://data.hexin.cn/ipo/sgdetail')) {
        print('blocking navigation to $request}');
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) {
            return DetailView(request.url);
          },
        ));
        return NavigationDecision.prevent;
      }
      //拦截无效地址
      if (request.url.startsWith('client://client.html')) {
        return NavigationDecision.prevent;
      }
      print('allowing navigation to $request');
      return NavigationDecision.navigate;
    };
    PageStartedCallback onPageStarted = (String url) {
      print('Page started loading: $url');
    };
    PageFinishedCallback onPageFinished = (String url) async {
      print('Page finished loading: $url');
      if (webViewController != null) {
        //关闭下载提示
        await webViewController.evaluateJavascript(
            "document.getElementsByClassName('appad')[0].style.visibility = 'hidden';");
      }
    };
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    String url = "http://data.hexin.cn/ipo/xgsgzq/";
    return Scaffold(
      appBar: AppBar(
        title: Text("IPO申购打新日历"),
        centerTitle: true,
      ),
      body: WillPopScope(
        onWillPop: () {
          if (lastClickTime == null ||
              DateTime.now().difference(lastClickTime) >
                  Duration(milliseconds: 1500)) {
            lastClickTime = DateTime.now();
            Fluttertoast.showToast(
              msg: "再按一次退出App",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
            return Future.value(false);
          } else {
            return Future.value(true);
          }
        },
        child: WebView(
          initialUrl: Uri.encodeFull(url),
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: onWebViewCreated,
          navigationDelegate: navigationDelegate,
          onPageStarted: onPageStarted,
          onPageFinished: onPageFinished,
          gestureNavigationEnabled: true,
        ),
      ),
    );
  }
}

Map<String, String> getNameCookies;

class DetailView extends StatefulWidget {
  String url = "";

  DetailView(
    this.url,
  );

  @override
  _DetailViewState createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  WebViewController webViewController;
  String code;

  @override
  void initState() {
    // 申购码 舍弃
    // final intRegex = RegExp(r'\d{6}');
    // code = intRegex.allMatches(widget.url).map((m) => m.group(0)).first;
  }

  void _beforeRequest(HttpClientRequest request) {
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip, deflate, br');
    // Set cookie
    if (getNameCookies != null) {
      final String rawCookies = getNameCookies.keys
          .map((String name) => '$name=${getNameCookies[name]}')
          .join('; ');
      if (rawCookies.isNotEmpty)
        request.headers.set(HttpHeaders.cookieHeader, rawCookies);
    }
  }

  void _afterResponse(HttpClientResponse response) {
    response.headers.forEach((String name, List<String> values) {
      if (name == 'set-cookie') {
        if (getNameCookies == null) {
          getNameCookies = {};
        }
        // Get cookies for next request
        values.forEach((String rawCookie) {
          try {
            Cookie cookie = Cookie.fromSetCookieValue(rawCookie);
            getNameCookies[cookie.name] = cookie.value;
          } catch (e) {
            final List<String> cookie = rawCookie.split(';')[0].split('=');
            getNameCookies[cookie[0]] = cookie[1];
          }
        });
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    WebViewCreatedCallback onWebViewCreated = (WebViewController controller) {
      webViewController = controller;
    };
    NavigationDelegate navigationDelegate = (NavigationRequest request) {
      //路由拦截
      if (request.url.startsWith('http://basic.10jqka.com.cn/mobile/')) {
        print('blocking navigation to $request}');
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) {
            return CompanyView(request.url, "公司资料");
          },
        ));
        return NavigationDecision.prevent;
      }
      print('allowing navigation to $request');
      return NavigationDecision.navigate;
    };
    PageFinishedCallback onPageFinished = (String url) async {
      print('Page finished loading: $url');
      if (webViewController != null) {
        //移除按钮
        await webViewController.evaluateJavascript(
            "document.getElementsByClassName('module')[0].style.visibility = 'hidden';");
        await webViewController.evaluateJavascript(
            "document.getElementsByClassName('botfixed')[0].style.visibility = 'hidden';");
        await webViewController.evaluateJavascript("""
          Ipo.postMessage(document.getElementsByClassName('txtr')[0].innerText);
          """);
      }
    };
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    return Scaffold(
      appBar: AppBar(
        title: Text("申购详情"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebView(
            initialUrl: Uri.encodeFull(widget.url),
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: onWebViewCreated,
            navigationDelegate: navigationDelegate,
            onPageFinished: onPageFinished,
            javascriptChannels: <JavascriptChannel>{
              _toasterJavascriptChannel(context),
            },
            gestureNavigationEnabled: true,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 20, bottom: 20),
              child: RawMaterialButton(
                onPressed: openingBook,
                fillColor: Theme.of(context).primaryColor,
                child: Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Text(
                    "打新必读分析",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Ipo',
        onMessageReceived: (JavascriptMessage message) {
          // ignore: deprecated_member_use
          code = message.message;
          print(code);
        });
  }

  HttpClient httpClient;

  //查找文章
  Future<void> searchArticle(String name) async {
    if (httpClient == null) {
      httpClient = new HttpClient();
    }
    if (getNameCookies == null) {
      Uri uri = new Uri.https('xueqiu.com', '/');
      var request = await httpClient.getUrl(uri);
      _beforeRequest(request);
      var response = await request.close();
      _afterResponse(response);
    }

    try {
      Uri uri = new Uri.https(
        'xueqiu.com',
        '/query/v1/search/status.json',
        {
          'q': "$name估值预测表",
          'sortId': "1",
        },
      );
      var request = await httpClient.getUrl(uri);
      _beforeRequest(request);
      var response = await request.close();
      _afterResponse(response);
      if (response.statusCode == HttpStatus.ok) {
        var jsonStr = await response.transform(utf8.decoder).join();
        Map<String, dynamic> data = json.decode(jsonStr);
        if (data != null && data["list"].length > 0) {
          List list = data["list"];
          dynamic article = list[0];
          if (article["user"]["screen_name"] == "打新必读") {
            String target = article["target"];
            String text = article["text"];
            String url = "https://xueqiu.com$target";
            print(url);
            Navigator.of(context).push(MaterialPageRoute(
              builder: (BuildContext context) {
                return CompanyView(url, "打新必读分析");
                // return AnalysisView(url, "打新必读分析", text);
              },
            ));
          } else {
            showErrorToast();
          }
        } else {
          showErrorToast();
        }
        print(data);
      } else {
        print('Error getting IP address:\nHttp status ${response.statusCode}');
        showErrorToast();
      }
    } catch (exception) {
      print('Failed getting IP address');
      showErrorToast();
    }
  }

  Future<void> getCode() async {
    await webViewController.evaluateJavascript("""
          Ipo.postMessage(document.getElementsByClassName('txtr')[0].innerText);
          """);
  }

  //打开分析
  Future<void> openingBook() async {
    if (httpClient == null) {
      httpClient = new HttpClient();
    }
    if (getNameCookies == null) {
      Uri uri = new Uri.https('xueqiu.com', '/');
      var request = await httpClient.getUrl(uri);
      _beforeRequest(request);
      var response = await request.close();
      _afterResponse(response);
    }
    try {
      Uri uri = new Uri.http(
        'xueqiu.com',
        '/query/v1/suggest_stock.json',
        {
          'q': code,
        },
      );
      var request = await httpClient.getUrl(uri);
      _beforeRequest(request);
      var response = await request.close();
      _afterResponse(response);
      if (response.statusCode == HttpStatus.ok) {
        var jsonStr = await response.transform(utf8.decoder).join();
        Map<String, dynamic> data = json.decode(jsonStr);
        if (data != null && data["data"].length > 0) {
          List list = data["data"];
          String name = list[0]["query"];
          print(name);
          searchArticle(name);
        } else {
          showErrorToast();
        }
      } else {
        print('Error getting IP address:\nHttp status ${response.statusCode}');
        showErrorToast();
      }
    } catch (exception) {
      print('Failed getting IP address');
      showErrorToast();
    }
  }

  /* //打开分析
  Future<void> openingBook() async {
    if (httpClient == null) {
      httpClient = new HttpClient();
    }
    if (getNameCookies == null) {
      Uri uri = new Uri.http('www.iwencai.com','/stockpick');
      var request = await httpClient.getUrl(uri);
      _beforeRequest(request);
      var response = await request.close();
      _afterResponse(response);
    }
    try {
      Uri uri = new Uri.http(
        'www.iwencai.com',
        '/stockpick/load-data',
        {
          'w': code,
          'querytype': 'stock',
        },
      );
      var request = await httpClient.getUrl(uri);
      _beforeRequest(request);
      var response = await request.close();
      _afterResponse(response);
      if (response.statusCode == HttpStatus.ok) {
        var jsonStr = await response.transform(utf8.decoder).join();
        Map<String, dynamic> data = json.decode(jsonStr);
        if (data != null && data["data"]["result"]["result"].length > 0) {
          List list = data["data"]["result"]["result"];
          String name = list[0][1];
          print(name);
          searchArticle(name);
        } else {
          showErrorToast();
        }
      } else {
        print('Error getting IP address:\nHttp status ${response.statusCode}');
        showErrorToast();
      }
    } catch (exception) {
      print('Failed getting IP address');
      showErrorToast();
    }
  }*/

  void showErrorToast() {
    Fluttertoast.showToast(
      msg: "访问失败",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }
}

class CompanyView extends StatefulWidget {
  String url = "";
  String title = "";

  CompanyView(this.url, this.title);

  @override
  _CompanyViewState createState() => _CompanyViewState();
}

class _CompanyViewState extends State<CompanyView> {
  WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    WebViewCreatedCallback onWebViewCreated = (WebViewController controller) {
      webViewController = controller;
    };
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    Function back = () async {
      if (webViewController == null) return;
      if (await webViewController.canGoBack()) {
        webViewController.goBack();
      } else {
        Navigator.of(context).pop();
      }
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
          ),
          onPressed: back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: WillPopScope(
        onWillPop: () {
          back();
          return Future.value(false);
        },
        child: WebView(
          initialUrl: Uri.encodeFull(widget.url),
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: onWebViewCreated,
          gestureNavigationEnabled: true,
        ),
      ),
    );
  }
}

class AnalysisView extends StatefulWidget {
  String url = "";
  String title = "";
  String text = "";

  AnalysisView(this.url, this.title, this.text);

  @override
  _AnalysisViewState createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    WebViewCreatedCallback onWebViewCreated = (WebViewController controller) {
      webViewController = controller;
    };
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    Function back = () async {
      if (webViewController == null) return;
      if (await webViewController.canGoBack()) {
        webViewController.goBack();
      } else {
        Navigator.of(context).pop();
      }
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
          ),
          onPressed: back,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: WillPopScope(
        onWillPop: () {
          back();
          return Future.value(false);
        },
        child: WebView(
          initialUrl: _updateUrl(widget.text),
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: onWebViewCreated,
          gestureNavigationEnabled: true,
        ),
      ),
    );
  }

  String _updateUrl(String url) {
    String _src = url;
    _src = "data:text/html;charset=utf-8," +
        Uri.encodeComponent(EasyWebViewImpl.wrapHtml(url));
    return _src;
  }
}
