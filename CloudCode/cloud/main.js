Parse.Cloud.define("like", function (request, respose) {
    Parse.Cloud.useMasterKey();
    var Node = Parse.Object.extend("Node");
    var query = new Parse.Query(Node);
    var nodeObjectId = request.params.node;
    var node;
    query.equalTo("objectId", nodeObjectId);
    query.first().then(function (result) {
        node = result
        var owner = result.get("owner");
        owner.increment("likes", 1);
        return owner.save();
    }).then(function (result) {
        var relation = node.relation("likesRelation");
        relation.add(request.user);
        return node.save();
    }).then(function (result) {
        respose.success();
    }, function (error) {
        respose.error(error);
    });
})