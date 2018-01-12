import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flux/flutter_flux.dart';

import 'package:hn_flutter/router.dart';
import 'package:hn_flutter/sdk/hn_auth_service.dart';
import 'package:hn_flutter/sdk/stores/hn_account_store.dart';

class MainDrawer extends StatefulWidget {
  MainDrawer ({Key key}) : super(key: key);

  @override
  _MainDrawerState createState () => new _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer>
  with SingleTickerProviderStateMixin, StoreWatcherMixin<MainDrawer> {

  Animation<double> _animation;
  AnimationController _controller;

  final HNAuthService _hnAuthService = new HNAuthService();
  HNAccountStore _accountStore;

  void initState () {
    super.initState();

    this._accountStore = listenToStore(accountStoreToken);

    _controller = new AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = new CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
        reverseCurve: Curves.easeOut,
      )
      // .animate(_controller)
      ..addListener(() {
        setState(() {
          // the state that has changed here is the animation object’s value
        });
      });
    // controller.forward();
  }

  void dispose () {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build (BuildContext context) {
    return new ListView(
      children: <Widget>[
        new UserAccountsDrawerHeader(
          accountEmail: this._accountStore.primaryAccount != null ? new Text(this._accountStore.primaryAccount.email ?? '...') : null,
          accountName: new Text(this._accountStore.primaryAccountId ?? 'Not logged in'),
          onDetailsPressed: this._toggleAccounts,
        ),
        new ClipRect(
          child: new Align(
            heightFactor: _animation.value,
            child: new Container(
              // color: Colors.grey[700],
              child: new Column(
                children: this._accountStore.accounts.values
                  // .where((account) => account.id != this._accountStore.primaryAccountId)
                  .map<Widget>((account) =>
                    new ListTile(
                      title: new Text(account.id),
                      trailing: new IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => _showRemoveAccountDialog(context, account.id),
                      ),
                      onTap: () async {
                        this._toggleAccounts();
                      },
                    )).toList()
                    ..addAll([
                      new ListTile(
                        title: new Text('Add account'),
                        trailing: const IconButton(
                          icon: const Icon(Icons.add),
                        ),
                        onTap: () async {
                          if (await this._showAddAccountDialog(context) ?? false) {
                            this._closeDrawer(context);
                          }
                        },
                      ),
                      const Divider(),
                    ]),
              ),
            ),
          ),
        ),
        new MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: new Column(
            children: <Widget>[
              new ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Open Story'),
                onTap: () async {
                  await this._showStoryDialog(context);
                  this._closeDrawer(context);
                },
              ),
              new ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Open User'),
                onTap: () async {
                  await this._showUserDialog(context);
                  this._closeDrawer(context);
                },
              ),
              const Divider(),
              new ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () async {
                  this._closeDrawer(context);
                  this._openSettings();
                }
              ),
            ],
          ),
        )
      ],
    );
  }

  void _closeDrawer (BuildContext ctx) {
    final scaffold = Scaffold.of(ctx);
    if (scaffold.hasDrawer) {
      Navigator.pop(ctx);
    }
  }

  void _toggleAccounts () {
    if (_controller.isAnimating) {
      if (_controller.velocity > 0) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    } else if (_controller.value == 0) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  _showStoryDialog (BuildContext ctx) async {
    String storyId;

    storyId = await showDialog(
      context: ctx,
      child: new SimpleDialog(
        title: const Text('Enter story ID'),
        contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        children: <Widget>[
          new TextField(
            autofocus: true,
            decoration: new InputDecoration(
              labelText: 'Story ID',
            ),
            keyboardType: TextInputType.number,
            onChanged: (String val) => storyId = val,
          ),
          new ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: new ButtonBar(
              children: <Widget>[
                new FlatButton(
                  child: new Text('Cancel'.toUpperCase()),
                  onPressed: () {
                    Navigator.pop(ctx);
                    this._closeDrawer(ctx);
                  },
                ),
                new FlatButton(
                  child: new Text('View'.toUpperCase()),
                  onPressed: () {
                    Navigator.pop(ctx, storyId);
                    this._closeDrawer(ctx);
                  },
                ),
              ],
            ),
          ),
        ],
      )
    );

    if (storyId != null) {
      print(storyId);
      Navigator.pushNamed(ctx, '/${Routes.STORIES}:$storyId');
    }
  }

  _showUserDialog (BuildContext ctx) async {
    String userId;

    userId = await showDialog(
      context: ctx,
      child: new SimpleDialog(
        title: const Text('Enter user ID'),
        contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        children: <Widget>[
          new TextField(
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.text,
            decoration: new InputDecoration(
              labelText: 'User ID',
            ),
            onChanged: (String val) => userId = val,
          ),
          new Container(
            height: 8.0,
          ),
          new ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: new ButtonBar(
              children: <Widget>[
                new FlatButton(
                  child: new Text('Cancel'.toUpperCase()),
                  onPressed: () => Navigator.pop(ctx),
                ),
                new FlatButton(
                  child: new Text('View'.toUpperCase()),
                  onPressed: () => Navigator.pop(ctx, userId),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  _showAddAccountDialog (BuildContext ctx) async {
    String userId = '';
    String userPassword = '';

    return await showDialog(
      context: ctx,
      child: new SimpleDialog(
        title: const Text('Login'),
        contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        children: <Widget>[
          new TextField(
            autofocus: true,
            autocorrect: false,
            keyboardType: TextInputType.text,
            decoration: new InputDecoration(
              labelText: 'User ID',
            ),
            onChanged: (String val) => userId = val,
          ),
          new TextField(
            autocorrect: false,
            keyboardType: TextInputType.text,
            obscureText: true,
            decoration: new InputDecoration(
              labelText: 'Password',
            ),
            onChanged: (String val) => userPassword = val,
          ),
          const Padding(
            padding: const EdgeInsets.only(top: 8.0),
          ),
          new ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: new ButtonBar(
              children: <Widget>[
                new FlatButton(
                  child: new Text('Cancel'.toUpperCase()),
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                ),
                new FlatButton(
                  child: new Text('Login'.toUpperCase()),
                  onPressed: () async {
                    print(userId);
                    await this._addAccount(ctx, userId, userPassword);
                    Navigator.pop(ctx, true);
                  },
                ),
              ],
            ),
          ),
        ],
      )
    );
  }

  _showRemoveAccountDialog (BuildContext ctx, String userId) async {
    return await showDialog(
      context: ctx,
      child: new SimpleDialog(
        title: new Text('Remove $userId?'),
        contentPadding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        children: <Widget>[
          new ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: new ButtonBar(
              children: <Widget>[
                new FlatButton(
                  child: new Text('Cancel'.toUpperCase()),
                  onPressed: () {
                    Navigator.pop(ctx, false);
                  },
                ),
                new FlatButton(
                  child: new Text('Remove'.toUpperCase()),
                  onPressed: () async {
                    await this._removeAccount(userId);
                    Navigator.pop(ctx, true);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _addAccount (BuildContext ctx, String userId, String userPassword) async {
    if (await this._hnAuthService.addAccount(userId, userPassword)) {
      Scaffold.of(ctx).showSnackBar(new SnackBar(
        content: new Text('Logged in'),
      ));
    } else {
      Scaffold.of(ctx).showSnackBar(new SnackBar(
        content: new Text('Failed to login'),
      ));
    }
  }

  _removeAccount (String userId) async {
    if (await this._hnAuthService.removeAccount(userId)) {
    } else {
    }
  }

  _openSettings () async {}
}