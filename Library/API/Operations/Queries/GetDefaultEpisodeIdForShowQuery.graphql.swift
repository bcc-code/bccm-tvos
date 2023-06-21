// @generated
// This file was automatically generated and should not be edited.

@_exported import Apollo

extension API {
  class GetDefaultEpisodeIdForShowQuery: GraphQLQuery {
    static let operationName: String = "GetDefaultEpisodeIdForShow"
    static let document: Apollo.DocumentType = .notPersisted(
      definition: .init(
        #"""
        query GetDefaultEpisodeIdForShow($id: ID!) {
          show(id: $id) {
            __typename
            defaultEpisode {
              __typename
              id
            }
          }
        }
        """#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    public var __variables: Variables? { ["id": id] }

    struct Data: API.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: Apollo.ParentType { API.Objects.QueryRoot }
      static var __selections: [Apollo.Selection] { [
        .field("show", Show.self, arguments: ["id": .variable("id")]),
      ] }

      var show: Show { __data["show"] }

      /// Show
      ///
      /// Parent Type: `Show`
      struct Show: API.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: Apollo.ParentType { API.Objects.Show }
        static var __selections: [Apollo.Selection] { [
          .field("__typename", String.self),
          .field("defaultEpisode", DefaultEpisode.self),
        ] }

        /// The default episode.
        /// Should not be used actively in lists, as it could affect query speeds.
        var defaultEpisode: DefaultEpisode { __data["defaultEpisode"] }

        /// Show.DefaultEpisode
        ///
        /// Parent Type: `Episode`
        struct DefaultEpisode: API.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: Apollo.ParentType { API.Objects.Episode }
          static var __selections: [Apollo.Selection] { [
            .field("__typename", String.self),
            .field("id", API.ID.self),
          ] }

          var id: API.ID { __data["id"] }
        }
      }
    }
  }

}