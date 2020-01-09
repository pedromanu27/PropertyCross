import QtQuick 2.0
import Felgo 3.0

Item {

    readonly property bool  loading: HttpNetworkActivityIndicator.enabled

    Component.onCompleted: {
        HttpNetworkActivityIndicator.activationDelay = 0
    }

    function search(text, callback) {
        _.sendRequest({
                          action: "search_listings",
                          page: 1,
                          place_name: text
                      }, callback)
    }

    function searchByLocation(latitude, longitude, callback) {
        _.sendRequest({
                          action: "search_listings",
                          page: 1,
                          centre_point: latitude + "," + longitude
                      }, callback)
    }

    function repeatForPage(page, callback) {
        var params = _.lastParamsMap
        params.page = page
        _.sendRequest(params, callback)
    }

    Item {
        id: _

        property var lastParamsMap: ({})

        readonly property string  serverUrl: "https://api.nestoria.com.br/api?encoding=json&pretty=1&country=br&listing_type=buy"


        function buildUrl(paramMap) {
            var url = serverUrl
            for (var param in paramMap) {
                url += "&" + param + "=" + paramMap[param]
            }
            return url
        }

        function sendRequest(paramMap, callback) {
            var method = "GET"
            var url = buildUrl(paramMap)
            console.debug(method + " " + url)

            HttpRequest.get(url)
            .then(function(res) {
                var content = res.text
                try {
                    var obj = JSON.parse(content)
                } catch (ex) {
                    console.error("Não foi possível analisar a resposta do servidor como JSON:", ex)
                    return
                }
                console.debug("Resposta JSON analisada com sucesso")
                callback(obj)
            })
            .catch(function(err) {
            })

            lastParamsMap = paramMap
        }
    }

}
