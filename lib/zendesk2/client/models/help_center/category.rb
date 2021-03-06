class Zendesk2::Client::HelpCenter::Category < Zendesk2::Model
  extend Zendesk2::Attributes

  # @return [Integer] Automatically assigned when creating categories
  identity :id, type: :integer # ro:yes required:no

  # @return [Time] The time at which the category was created
  attribute :created_at, type: :time # ro:yes required:no
  # @return [String] The description of the category
  attribute :description, type: :string # ro:no required:no
  # @return [String] The url of this category in Help Center
  attribute :html_url, type: :string # ro:yes required:no
  # @return [String] The locale that the category is displayed in
  attribute :locale, type: :string # ro:no required:yes
  # @return [String] The name of the category
  attribute :name, type: :string # ro:no required:yes
  # @return [Boolean] Whether the category is out of date
  attribute :outdated, type: :boolean # ro:yes required:no
  # @return [Integer] The position of this category relative to other categories
  attribute :position, type: :integer # ro:no required:no
  # @return [String] The source (default) locale of the category
  attribute :source_locale, type: :string # ro:yes required:no
  # @return [Array] The ids of all translations of this category
  attribute :translation_ids, type: :array # ro:yes required:no
  # @return [Time] The time at which the category was last updated
  attribute :updated_at, type: :time # ro:yes required:no
  # @return [String] The API url of this category
  attribute :url, type: :string # ro:yes required:no

  def save!
    requires :name, :locale

    data = if new_record?
             connection.create_help_center_category(params).body["category"]
           else
             connection.update_help_center_category(dirty_attributes.merge("id" => self.identity)).body["category"]
           end

    merge_attributes(data)
  end

  def destroy!
    requires :id

    connection.destroy_help_center_category(id)
  end

  private

  def params
    Cistern::Hash.slice(self.attributes, :category_id, :description, :locale, :name, :position, :sorting)
  end
end
