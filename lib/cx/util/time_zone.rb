require 'date'
require 'tzinfo'
require 'cx/core'

module TimeZone

  def yahoo_exchange_timezones
    @yahoo_exchange_timezones ||= {
      CCY:  'Europe/London',    # currency
      ASX:  'Australia/Sydney', # ASX
      NYQ:  'America/New_York', # NY X
      NMS:  'America/New_York', # NASDAQ
      PNK:  'America/New_York', # Pink Sheets ?
    }
  end

  def exchange_timezones
    unless @exchange_timezones
      @exchange_timezones = {}
      yahoo_exchange_timezones.each do |k, v|
        @exchange_timezones[k] = TZInfo::Timezone.get(v)
      end
    end
    @exchange_timezones
  end

  def tz_utc
    @tz_utc ||= TZInfo::Timezone.get('UTC')
  end

  def exchange_tz(exchange)
    exchange_timezones[exchange.to_sym] || tz_utc
  end

  def adjust_datetime(datetime, offset_minutes)
    day_offset = 0
    secs = (datetime.hour * 3600) + (datetime.minute * 60) + datetime.second + (offset_minutes * 60)
    secs_per_day = 24 * 60 * 60
    if secs > secs_per_day
      day_offset += 1
      secs -= secs_per_day
    elsif secs < 0
      day_offset -= 1
      secs += secs_per_day
    end
    hour = (secs / 3600).truncate
    minute = ((secs - (hour * 3600)) / 60).truncate
    second = secs - ((hour * 3600) + (minute * 60))
    DateTime.new(datetime.year, datetime.month, datetime.day, hour, minute, second) + day_offset
  end

  def offset_hhmm(arg_offset_minutes)
    # fail "offset must be integer" unless arg_offset_minutes.is_a?(Integer)
    sign = arg_offset_minutes < 0 ? -1 : 1
    offset_minutes = arg_offset_minutes * sign
    h = (offset_minutes / 60).truncate
    m = offset_minutes - (h * 60)
    "#{sign < 0 ? '-' : '+'}#{'%02d' % h}:#{'%02d' % m}"
  end

  def hhmm_to_minutes(hhmm)
    h, m = hhmm.split(':')
    (h * 60) + (h < 0 ? -m : m)
  end

  def ymdhmso(datetime, offset = nil)
    # fail "offset must be integer" unless offset.is_a?(Integer)
    ymdhms = datetime.ymdhms(date_sep: '-', time_sep: ':')
    ohhmms = offset ? offset_hhmm(offset) : datetime.strftime('%Z')
    "#{ymdhms} #{ohhmms}"
  end

  # Exchange should be the (Yahoo) exchange name.
  # EG: CCY ASX NYQ NMS PNK
  def exchange_ymdhmso(exchange_ymdhms, exchange)
    exchange_tz = exchange_tz(exchange)
    exchange_time = DateTime.parse(exchange_ymdhms)
    exchange_tz_offset = (exchange_tz.period_for_local(exchange_time).offset.utc_total_offset / 60).truncate
    ymdhmso(exchange_time, exchange_tz_offset)
  end

  # Converts ymdhmso to UTC.
  # Unless an offset is explicitly given, then
  # the offset (if any) in the ymdhmso string
  # will be used.
  # EG "20151231 2359 +01:30" or "20151231 2359 -14:00".
  # Spaces are used as separators.
  def utc_ymdhmso(ymdhmso, arg_offset = nil)
    local = DateTime.parse(ymdhmso)
    offset = arg_offset
    unless offset
      tz = local.strftime('%Z')
      offset = hhmm_to_minutes(tz)
    end
    utc = adjust_datetime(local, offset)
    ymdhmso(utc, 0)
  end

  # Expects UTC ymdhms
  def local_ymdhmso(utc_ymdhms, local_offset)
    utc = DateTime.parse(utc_ymdhms)
    client = adjust_datetime(utc, local_offset)
    ymdhmso(client, local_offset)
  end

end
