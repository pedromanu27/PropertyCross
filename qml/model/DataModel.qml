import QtQuick 2.0
import QtPositioning 5.12
import Qt.labs.settings 1.1

Item {

    property alias dispatcher: logicConnection.target

    signal listingsReceived
    signal locationReceived

    readonly property var location: positionSource.coordinate

    readonly property bool loading: client.loading || positionSource.active

    readonly property alias numTotalListings: _.numTotalListings

    readonly property int  numListings: _.listings.length

    readonly property var listings: _.createListingsModel(_.listings)

    readonly property var favoriteListings: _.createListingsModel(_.favoriteListingsValues, true)

    readonly property var locations: _.createLocationsModel()

    readonly property var recentSearches: _.createRecentSearchesModel()

    readonly property bool isSuggested: _.locationSource === _.locationSourceSuggested
    readonly property bool isRecent: _.locationSource === _.locationSourceRecent
    readonly property bool isError: _.locationSource === _.locationSourceError

    readonly property bool positioningSupported: positionSource.supportedPositioningMethods !==
                                                 PositionSource.NoPositioningMethods &&
                                                 positionSource.valid

    Connections {
        id: logicConnection

        onUseLocation: {
            if (positionSource.position.coordinate.isValid) {
                _.searchByLocation()
            } else {
                _.locationSearchPending = true
                positionSource.update()
            }
        }

        onSearchListings: {
            _.lastSearchText = addToRecents ? searchText : ""
            _.listings = []
            client.search(searchText, _.responseCallback)
        }

        onShowRecentSearches: {
            _.locationSource = _.locationSourceRecent
        }

        onLoadNextPage: {
            client.repeatForPage(_.currentPage + 1, _.responseCallback)
        }

        onToggleFavorite: {
            var listingDataStr = JSON.stringify(listingData)
            var index = _.favoriteListingsValues.indexOf(listingDataStr)

            if (index < 0) {
                _.favoriteListingsValues.push(listingDataStr)
            } else {
                _.favoriteListingsValues.splice(index, 1)
            }

            _.favoriteListingsValuesChanged()
        }
    }

    function isFavorite(listingData) {
        return _.favoriteListingsValues.indexOf(JSON.stringify(listingData)) >= 0
    }

    Settings {
        property string recentSearches: JSON.stringify(_.recentSearches)
        property string favoriteListingsValues: JSON.stringify(_.favoriteListingsValues)

        Component.onCompleted: {
            _.recentSearches = recentSearches && JSON.parse(recentSearches) || {}
            _.favoriteListingsValues = favoriteListingsValues && JSON.parse(favoriteListingsValues) || []
        }
    }

    Client {
        id: client
    }

    PositionSource {
        id: positionSource
        active: false

        onActiveChanged: {
            var coord = position.coordinate
            console.log("Coordenates:", coord.latitude, coord.longitude,
                        "valid:", coord.isValid,
                        "source active:", active)

            if(!active) {
                if (coord.isValid && _.locationSearchPending) {
                    _.searchByLocation()
                    _.locationSearchPending = false
                }
            }
        }

        onUpdateTimeout: console.log("location timed out")
    }

    Item {
        id: _

        property int  locationSource: locationSourceRecent

        property var favoriteListingsValues: []

        property var recentSearches: ({})

        property var locations : []
        property var listings: []
        property int  numTotalListings

        property int  currentPage: 1

        property string lastSearchText: ""

        readonly property int  locationSourceSuggested: 1
        readonly property int  locationSourceRecent: 2
        readonly property int  locationSourceError: 3

        readonly property var successCodes: ["100", "101", "110"]
        readonly property var ambiguousCodes: ["200", "202"]

        property bool locationSearchPending: false

        function searchByLocation() {
            locationReceived()
            var coord = positionSouce.position.coordinate
            client.searchByLocation(coord.latitude, coord.longitude, _.responseCallback)
        }

        function responseCallback(obj) {
            var response = obj.response
            var code = response.application_response_code
            console.debug("Server returned application code: ",code)

            if(successCodes.indexOf(code) >= 0) {
                currentPage = parseInt(response.page)
                listings = listings.concat(response.listings)
                listingsReceived()
                numTotalListings = response.total_results || 0
                console.debug("Server returned", response.listings.length, "listings")
                addRecentSearch(qsTr("%1 (%2 listings)").arg(lastSearchText).arg(numTotalListings))
                locationSource = locationSourceSuggested
            } else if (ambiguousCodes.indexOf(code) >= 0) {
                locations = response.locations
            }
            else if(code === "210") {
                locations = []
                locationSource = locationSourceSuggested
            }
            else {
                locations = []
                locationSource = locationSourceError
            }
        }

        function createLocationsModel() {
            return locations.map(function(data) {
                return {
                    heading: "Por favor selecione um local abaixo",
                    text: data.title,
                    detailText: data.long_title,
                    model: data,
                    seharchText: data.place_name
                }
            })
        }

        function createRecentSearchesModel() {
            return Object.keys(recentSearches).map(function(text) {
                return {
                    heading: "Buscas recentes",
                    text: recentSearches[text].displayText,
                    searchText: text
                }
            })
        }

        function createListingsModel(source, parseValues) {
            return source.map(function (data) {
                if (parseValues)
                    data = JSON.parse(data)

                return {
                    text: data.price_formatted,
                    detailText: data.title,
                    image: data.thumb_url,
                    model: data
                }
            })
        }

        function addRecentSearch(displayText) {
            if (lastSearchText) {
                recentSearches[lastSearchText] = {
                    displayText: displayText
                }
                console.debug("add recente")
                _.recentSearchesChanged()
            }
        }
    }

}
