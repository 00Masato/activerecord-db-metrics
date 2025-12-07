# frozen_string_literal: true

require 'active_support'
require 'active_record'

require_relative 'activerecord/db/metrics/version'
require_relative 'activerecord/db/metrics/collector'
require_relative 'activerecord/db/metrics/controller_helper'

module ActiveRecord
  module Db
    module Metrics
      class Error < StandardError; end
    end
  end
end
