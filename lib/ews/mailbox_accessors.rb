=begin
  This file is part of Viewpoint; the Ruby library for Microsoft Exchange Web Services.

  Copyright © 2011 Dan Wanek <dan.wanek@gmail.com>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
=end

module Viewpoint::EWS::MailboxAccessors
  include Viewpoint::EWS

  # Resolve contacts in the Exchange Data Store
  # @param [String] ustring A string to resolve contacts to.
  # @return [Array<MailboxUser>] It returns an Array of MailboxUsers.
  def search_contacts(ustring)
    resp = ews.resolve_names(:name => ustring)

    users = []
    if(resp.status == 'Success')
      users = resp.response_message[:elems][:resolution_set][:elems]
      # users << Types::MailboxUser.new(ews, mb[:mailbox][:elems])
    elsif(resp.code == 'ErrorNameResolutionMultipleResults')
      users = resp.response_message[:elems][:resolution_set][:elems].select do |u|
        !!u[:resolution][:elems][0][:mailbox]
      end
    elsif resp.code != 'ErrorNameResolutionNoResults'
      raise EwsError, "Find User produced an error: #{resp.code}: #{resp.message}"
    end
    users
  end

  # GetUserAvailability request
  # @see http://msdn.microsoft.com/en-us/library/aa563800.aspx
  # @param [Array<String>] emails A list of emails you want to retrieve free-busy info for.
  # @param [Hash] opts
  # @option opts [DateTime] :start_time
  # @option opts [DateTime] :end_time
  # @option opts [String] :routing_type should be one of the ConnectingSID variables Viewpoint::EWS::ConnectingSID
  # @option opts [Symbol] :requested_view :merged_only/:free_busy/
  #   :free_busy_merged/:detailed/:detailed_merged
  # @option opts [Hash] :time_zone The TimeZone data
  #   Example: {:bias => 'UTC offset in minutes',
  #   :standard_time => {:bias => 480, :time => '02:00:00',
  #     :day_order => 5, :month => 10, :day_of_week => 'Sunday'},
  #   :daylight_time => {same options as :standard_time}}
  def get_user_availability(emails, opts)
    opts = opts.clone
    args = get_user_availability_args(emails, opts)
    resp = ews.get_user_availability(args.merge(opts))
    get_user_availability_parser(resp)
  end


private

  def get_user_availability_args(emails, opts)
    unless opts.has_key?(:start_time) && opts.has_key?(:end_time) && opts.has_key?(:requested_view)
      raise EwsBadArgumentError, "You must specify a start_time, end_time and requested_view."
    end

    routing = opts[:routing_type]

    default_args = {
      mailbox_data: (emails.collect{ |e|
        user = {address: e}
        user[:routing_type] = routing if routing
        [email: user]
      }.flatten),
      free_busy_view_options: {
        time_window: {
          start_time: opts[:start_time],
          end_time: opts[:end_time]
        },
        requested_view: { :requested_free_busy_view => opts[:requested_view] },
      }
    }
  end

  def get_user_availability_parser(resp)
    if(resp.status == 'Success')
      resp
    else
      raise EwsError, "GetUserAvailability produced an error: #{resp.code}: #{resp.message}"
    end
  end

end # Viewpoint::EWS::MailboxAccessors
