class Zendesk2::Client
  class Real
    def get_user(params={})
      id = params["id"]

      request(
        :method => :get,
        :path => "/users/#{id}.json"
      )
    end
  end # Real

  class Mock
    def get_user(params={})
      id   = params["id"]

      identities = self.data[:identities].values.select{|i| i["user_id"] == id}
      identity = identities.find { |i| i["type"] == "email" && i["primary"] } || identities.find { |i| i["type"] == "email" }

      # @todo what happens if no identity?

      response(
        :path  => "/users/#{id}.json",
        :body  => {
          "user" => find!(:users, id).merge("email" => identity["value"]),
        },
      )
    end
  end # Mock
end
