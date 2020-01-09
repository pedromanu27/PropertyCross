import QtQuick 2.0
import Felgo 3.0

ListPage {

    id: listPageWrapper

    property var scrollPos: null
    property bool  favorites

    Component {
        id: detailPageComponent
        ListingDetailPage { }
    }

    rightBarItem: ActivityIndicatorBarItem {
        visible: dataModel.loading
    }

    model: JsonListModel {
        id: listModel
        source: favorites ? dataModel.favoriteListings : dataModel.listings
        fields: ["text", "detailText", "image", "model"]
    }

    title: favorites
           ? qsTr("Favoritos")
           : qsTr("%1 de %2 resultados").arg(dataModel.numListings).arg(dataModel.numTotalListings)

    emptyText.text: favorites
                    ? qsTr("Você não adicionou nenhuma propriedade aos seus favoritos.")
                    : qsTr("Nenhuma listagem disponível")

    listView.footer: VisibilityRefreshHandler {
        visible: !favorites && dataModel.numListings < dataModel.numTotalListings

        onRefresh: {
            scrollPos = listView.getScrollPosition()
            logic.loadNextPage()
        }
    }

    delegate: SimpleRow {
        item: listModel.get(index)
        autoSizeImage: true
        imageMaxSize: dp(40)
        image.fillMode: Image.PreserveAspectCrop

        onSelected: navigationStack.popAllExceptFirstAndPush(detailPageComponent, {model: item.model})
    }

    listView.onModelChanged: if(scrollPos) listView.restoreScrollPosition(scrollPos)

}
