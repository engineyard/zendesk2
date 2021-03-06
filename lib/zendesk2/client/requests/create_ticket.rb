class Zendesk2::Client
  class Real
    def create_ticket(params={})
      request(
        :body   => {"ticket" => params},
        :method => :post,
        :path   => "/tickets.json",
      )
    end
  end # Real

  class Mock
    def create_ticket(params={})
      params = Cistern::Hash.stringify_keys(params)

      identity = self.class.new_id

      if params["description"].nil? || params["description"] == ""
        error!(:invalid, :details => {"base" => [{"description" => "Description: cannot be blank"}]})
      end

      if requester = params.delete('requester')
        if !requester['name'] || requester['name'].size < 1
          response(
            :path   => "/tickets.json",
            :method => :post,
            :status => 422,
            :body   => {
              "error"       => "RecordInvalid",
              "description" => "Record validation errors",
              "details"     => {
                "requester" => [
                  {
                    "description" => "Requester Name:  is too short (minimum is 1 characters)"
                  }
                ]}})
        end

        user_id = if known_user = self.users.search(email: requester['email']).first
                    known_user.identity
                  else
                    # name is not required in this case
                    create_user(requester).body["user"]["id"]
                  end

        params['requester_id'] = user_id
      end

      requested_custom_fields = (params.delete("custom_fields") || [])

      custom_fields = requested_custom_fields.map do |cf|
        field_id = cf["id"].to_i
        if self.data[:ticket_fields][field_id]
          {"id" => field_id, "value" => cf["value"] }
        end
      end.compact

      self.data[:ticket_fields].each do |field_id, field|
        requested_custom_fields.find { |cf| cf["id"] == field_id } ||
          custom_fields << {"id" => field_id, "value" => nil }
      end

      record = {
        "id"               => identity,
        "url"              => url_for("/tickets/#{identity}.json"),
        "created_at"       => Time.now.iso8601,
        "updated_at"       => Time.now.iso8601,
        "priority"         => nil,
        "collaborator_ids" => [],
        "custom_fields"    => custom_fields,
      }.merge(params)

      record["requester_id"] ||= current_user["id"]
      record["submitter_id"] = current_user["id"]

      # FIXME: throw error if user doesn't exist?
      requester = self.data[:users][record["requester_id"]]
      record["organization_id"] = requester["organization_id"]

      self.data[:tickets][identity] = record

      response(
        :method => :post,
        :body   => {"ticket" => record},
        :path   => "/tickets.json"
      )
    end
  end # Mock
end # Zendesk2::Client
