part of dslink.responder;

typedef Map _FunctionCallback(String path, Map params);

class SimpleNodeProvider extends NodeProviderImpl {
  final Map<String, LocalNode> nodes = new Map<String, LocalNode>();

  LocalNode getNode(String path) {
    if (nodes.containsKey(path)) {
      return nodes[path];
    }
    var node = new SimpleNode(path);
    nodes[path] = node;
    return node;
  }
  SimpleNodeProvider([Map m]) {
    SimpleNode root = getNode("/");
    if (m != null) {
      root.load(m, this);
    }
  }
  void init([Map m]) {
    SimpleNode root = getNode("/");
    if (m != null) {
      root.load(m, this);
    }
  }
  void updateValue(String path, Object value) {
    SimpleNode node = getNode(path);
    node.updateValue(value);
  }
  void addNode(String path, Map m) {
    if (path == '/' || !path.startsWith('/')) return;
    SimpleNode node = getNode(path);
    node.load(m, this);
    
    Path p = new Path(path);
    SimpleNode pnode = getNode(p.parentPath);
    pnode.children[p.name] = node;
    pnode.updateList(p.name);
  }
  void removeNode(String path) {
    if (path == '/' || !path.startsWith('/')) return;
    SimpleNode node = getNode(path);
    // TODO update node's list status
    Path p = new Path(path);
    SimpleNode pnode = getNode(p.parentPath);
    pnode.children.remove(p.name);
    pnode.updateList(p.name);
  }
}

class SimpleNode extends LocalNodeImpl {
  SimpleNode(String path) : super(path);

  _FunctionCallback invokeCallback;

  void load(Map m, NodeProviderImpl provider) {
    if (_loaded) {
      configs.clear();
      attributes.clear();
      children.clear();
    }
    String childPathPre;
    if (path == '/') {
      childPathPre = '/';
    } else {
      childPathPre = '$path/';
    }
    m.forEach((String key, value) {
      if (key.startsWith('?')) {
        if (key == '?invoke') {
          if (value is _FunctionCallback) {
            invokeCallback = value;
          } else {
            print('$value is not a valid FunctionCallback: $_FunctionCallback');
          }
        } else if (key == '?value') {
          updateValue(value);
        }
      } else if (key.startsWith(r'$')) {
        configs[key] = value;
      } else if (key.startsWith('@')) {
        attributes[key] = value;
      } else if (value is Map) {
        String childPathpath;
        Node node = provider.getNode('$childPathPre$key');
        children[key] = node;
        if (node is LocalNodeImpl) {
          node.load(value, provider);
        }
      }
    });
    _loaded = true;
  }

  InvokeResponse invoke(Map params, Responder responder, InvokeResponse response) {
    if (invokeCallback != null) {
      Map rslt = invokeCallback(path, params);
      if (rslt != null) {
        response.updateStream([rslt], streamStatus: StreamStatus.closed);
      } else {
        response.close();
      }
    }
    return response;
  }
}
