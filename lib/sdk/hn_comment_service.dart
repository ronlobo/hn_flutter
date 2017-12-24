import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert' show JSON;

import 'package:hn_flutter/sdk/hn_config.dart';
import 'package:hn_flutter/sdk/models/hn_item.dart';
import 'package:hn_flutter/sdk/actions/hn_item_actions.dart';

class HNCommentService {
  HNConfig _config = new HNConfig();

  getChildComments (HNItem item) async {
    item.kids.forEach((child) => http.get('${this._config.url}/item/$child')
      .then((res) => JSON.decode(res.body))
      .then((List<int> body) => body.sublist(0, 5))
      .then((List<int> body) => Future.wait(body.map((itemId) => this.getItemByID(itemId)).toList()))
      .then((List<HNItem> children) {
        children.forEach((child) => addHNItem(child));
      })
    );
  }

  Future<HNItem> getItemByID (int id) {
    addHNItem(new HNItem(id: id, computed: new HNItemComputed(loading: true)));

    return http.get('${this._config.url}/item/$id.json')
      .then((res) => JSON.decode(res.body))
      .then((item) => new HNItem.fromMap(item))
      .then((item) {
        addHNItem(item);
      });
  }
}