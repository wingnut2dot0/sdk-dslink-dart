import 'dart:io';
import 'package:dslink/http_server.dart';
import 'package:dslink/responder.dart';
import 'package:dslink/common.dart';
import 'dart:async';

void main() {
  // load certificate
  String certPath = Platform.script.resolve('certs').toFilePath();
  SecureSocket.initialize(database: certPath, password: 'mypassword');

  // start the server
  var server = new DsHttpServer.start(InternetAddress.ANY_IP_V4, certificateName: "self signed for dart", nodeProvider: new TestNodeProvider());
}

class TestNodeProvider extends NodeProvider {
  TestNode onlyNode = new TestNode('/');
  ResponderNode getNode(String path) {
    return onlyNode;
  }
}

class TestNode extends ResponderNode {
  TestNode(String path) : super(path) {
    new Timer.periodic(const Duration(seconds: 5), updateTime);
  }

  ValueController value = new ValueController();
  int count = 0;
  void updateTime(Timer t) {
    value.controller.add(new RespValue(count++, (new DateTime.now()).toUtc().toIso8601String()));
  }

  bool get exists => true;

  Response invoke(Map params, Responder responder, Response response) {
    responder.updateReponse(response, [[1, 2]], status: StreamStatus.closed, columns: [{
        'name': 'v1',
        'type': 'number'
      }, {
        'name': 'v2',
        'type': 'number'
      }]);
    return response;
  }

  Response list(Responder responder, Response response) {
    responder.updateReponse(response, [[r'$is', 'testNode']], status: StreamStatus.closed);
    return response;
  }

  Response removeAttribute(String name, Responder responder, Response response) {
    return response;
  }

  Response removeConfig(String name, Responder responder, Response response) {
    return response;
  }

  Response setAttribute(String name, String value, Responder responder, Response response) {
    return response;
  }

  Response setConfig(String name, Object value, Responder responder, Response response) {
    return response;
  }

  Response setValue(Object value, Responder responder, Response response) {
    return response;
  }

  RespSubscribeController subscribe(SubscribeResponse subscription, Responder responder) {
    return new RespSubscribeController(subscription, this, value);
  }

}
