import 'package:xmpp_stone/xmpp_stone.dart' as xmpp;

main(List<String> arguments) {
  xmpp.Connection connection = connectUser();
  addConnectionStateListener(connection);
}

xmpp.Connection connectUser() {
  var userAtDomain = 'shubham@whocares.app';
  var password = '123456';

  xmpp.Jid jid = xmpp.Jid.fromFullJid(userAtDomain);
  xmpp.XmppAccountSettings account = xmpp.XmppAccountSettings(
    userAtDomain,
    jid.local,
    jid.domain,
    password,
    5222,
    host: '167.99.197.0',
  );
  xmpp.Connection connection = xmpp.Connection(account);
  connection.connect();
  return connection;
}

void addConnectionStateListener(xmpp.Connection connection) {
  ExampleConnectionStateChangedListener(connection);
}

class ExampleConnectionStateChangedListener
    implements xmpp.ConnectionStateChangedListener {
  xmpp.Connection _connection;
  xmpp.VCardManager _vCardManager;
  xmpp.MessageHandler _messageHandler;
  xmpp.RosterManager _rosterManager;
  xmpp.PresenceManager _presenceManager;
  xmpp.Jid _receiverJid;

  ExampleConnectionStateChangedListener(xmpp.Connection connection) {
    _connection = connection;
    _connection.connectionStateStream.listen(onConnectionStateChanged);
    _vCardManager = xmpp.VCardManager(_connection);
    _messageHandler = xmpp.MessageHandler.getInstance(_connection);
    _rosterManager = xmpp.RosterManager.getInstance(_connection);
    _presenceManager = xmpp.PresenceManager.getInstance(_connection);
  }

  @override
  void onConnectionStateChanged(xmpp.XmppConnectionState state) {
    if (state == xmpp.XmppConnectionState.Ready) {
      print("CONNECTED");
      getMyVCard();

      //add online listener
      addPresenceListener();

      //get all roster contact
      _getChatRoster();

      //add a receiver
      addBuddyReceiver();

      //add message listener
      addNewMessageReceivedListener();

      //send meassage
      sendMessage();
    }
  }

  void getMyVCard() {
    _vCardManager.getSelfVCard().then((vCard) {
      if (vCard != null) {
        print("MY VCARD : " + vCard.buildXmlString());
      }
    });
  }

  void addBuddyReceiver() {
    var receiver = "vaibhav@whocares.app";
    _receiverJid = xmpp.Jid.fromFullJid(receiver);
    _rosterManager.addRosterItem(xmpp.Buddy(_receiverJid)).then((result) {
      if (result.description != null) {
        print("add roster" + result.description);
      }
    });
    getBuddyVCard();
  }

  void addNewMessageReceivedListener() {
    _messageHandler.messagesStream
        .listen(ExampleMessagesListener().onNewMessage);
  }

  void addPresenceListener() {
    _presenceManager.subscriptionStream.listen((streamEvent) {
      if (streamEvent.type == xmpp.SubscriptionEventType.REQUEST) {
        print("Accepting presence request");
        _presenceManager.acceptSubscription(streamEvent.jid);
      }
    });
    _presenceManager.presenceStream.listen(onPresence);
  }

  void sendMessage() {
    _messageHandler.sendMessage(_receiverJid, 'Hi this is Vaibhav');
  }

  void getBuddyVCard() {
    _vCardManager.getVCardFor(_receiverJid).then((vCard) {
      if (vCard != null) {
        print("RECEIVER VCARD : " + vCard.buildXmlString());
      }
    });
  }

  void onPresence(xmpp.PresenceData event) {
    print(
        "PRESENCE EVENT FROM ${event.jid.fullJid} PRESENCE: ${event.showElement.toString()}");
  }

  void _getChatRoster() {
    _rosterManager.rosterStream.listen((event) {
      print("Roster -> " + event.toString());
    });
  }
}

class ExampleMessagesListener implements xmpp.MessagesListener {
  @override
  onNewMessage(xmpp.MessageStanza message) {
    if (message.body != null) {
      print(
          "New Message from ${message.fromJid.userAtDomain} message: ${message.body}");
    }
  }
}
