module ServiceTrade
  class Appointment
    extend ServiceTrade::ApiOperations::Create
    extend ServiceTrade::ApiOperations::List
    extend ServiceTrade::ApiOperations::Update
    extend ServiceTrade::ApiOperations::Delete

    OBJECT_NAME = 'appointment'

    def self.resource_url
      OBJECT_NAME
    end
  end
end
