import QtQuick 2.0
import Felgo 3.0

Page {

    id: searchPage
    title: qsTr("Propriedades")

    rightBarItem: NavigationBarRow {
        ActivityIndicatorBarItem {
            visible: dataModel.loading
            showItem: showItemAlways
        }

        IconButtonBarItem {
            icon: IconType.heart
            onClicked: showListings(true)
            title: qsTr("Favoritos")
        }
    }

    Column {
        id: contentCol
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: contentPadding
        spacing: contentPadding

        AppText {
            width: parent.width
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: sp(12)
            text: qsTr("Use o formulário abaixo para procurar casas para comprar. Você pode pesquisar por nome do local, código postal ou clicar em 'Meu local', para pesquisar no seu local atual.")
        }

        AppText {
            width: parent.width
            font.pixelSize: sp(12)
            color: Theme.secondaryTextColor
            font.italic: true
            text: qsTr("Dica: você pode encontrar e visualisar resultados rapidamente pesquisando 'Brasília'.")
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        AppTextField {
            id: searchInput
            width: parent.width

            showClearButton: true
            placeholderText: qsTr("Cidade")
            inputMethodHints: Qt.ImhNoPredictiveText

            onTextChanged: showRecentSearches()
            onEditingFinished: if (navigationStack.currentPage === searchPage) search()
        }

        Row {
            spacing: contentPadding

            AppButton {
                text: qsTr("Buscar")
                onClicked: search()
            }

            AppButton {
                text: qsTr("Meu local")
                enabled: dataModel.positioningSupported

                onClicked: {
                    searchInput.text = ""
                    searchInput.placeholderText = qsTr("Procurando localização...")
                    logic.useLocation()
                }
            }
        }

        AppText {
            visible: dataModel.isError
            text: qsTr("Ocorreu um problema com sua pesquisa")
        }
    }

    AppListView {
        id: listView

        width: parent.width
        anchors.top: contentCol.bottom
        anchors.bottom: parent.bottom

        visible: !dataModel.isError

        model: JsonListModel {
            source: dataModel.isRecent ? dataModel.recentSearches : dataModel.locations
            keyField: "searchText"
            fields: ["searchText", "heading", "text", "model", "detailText"]
        }

        section.property: "heading"
        section.delegate: SimpleSection { }

        delegate: SimpleRow {
            item: listView.model.get(index)

            onSelected: logic.searchListings(item.searchText, false)
        }

        emptyText.text: dataModel.isRecent ? qsTr("Nenhuma pesquisa recente") : qsTr("Nenhum local sugerido")
    }

    Connections {
        target: dataModel
        onListingsReceived: showListings(false)
        onLocationReceived: if (searchInput.placeholderText === "Procurando localização...") searchInput.placeholderText = "Buscar"
    }

    Component {
        id: listPageComponent
        ListingsListPage {}
    }

    function showListings(favorites) {

        console.debug("Chegou aqui")
        if (navigationStack.depth === 1) {
            navigationStack.popAllExceptFirstAndPush(listPageComponent, {favorites: favorites})
        }
    }

    function search() {
        logic.searchListings(searchInput.text, true);
    }

    function showRecentSearches() {
        logic.showRecentSearches()
    }

}
