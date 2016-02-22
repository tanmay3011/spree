module Spree
  class State < Spree::Base
    belongs_to :country, class_name: 'Spree::Country'
    has_many :addresses, dependent: :restrict_with_error

    has_many :zone_members,
             -> { where(zoneable_type: 'Spree::State') },
             class_name: 'Spree::ZoneMember',
             dependent: :destroy,
             foreign_key: :zoneable_id

    has_many :zones, through: :zone_members, class_name: 'Spree::Zone'

    validates :country, :name, presence: true
    validate :ensure_country_states_required?

    delegate :states_required?, to: :country, prefix: true, allow_nil: true


    self.whitelisted_ransackable_attributes = %w(abbr)

    def self.find_all_by_name_or_abbr(name_or_abbr)
      where('name = ? OR abbr = ?', name_or_abbr, name_or_abbr)
    end

    # table of { country.id => [ state.id , state.name ] }, arrays sorted by name
    # blank is added elsewhere, if needed
    def self.states_group_by_country_id
      state_info = Hash.new { |h, k| h[k] = [] }
      self.order(:name).each { |state|
        state_info[state.country_id.to_s].push [state.id, state.name]
      }
      state_info
    end

    def <=>(other)
      name <=> other.name
    end

    def to_s
      name
    end

    private
      def ensure_country_states_required?
        unless country_states_required?
          errors.add(:base, Spree.t(:country_states_required_unchecked))
        end
      end
  end
end
