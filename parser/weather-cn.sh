# weather-cn.sh ---
#
# Filename: weather-cn.sh
# Description: a parser fo weather_catcher
# Author: Xu FaSheng
# Created: 2012.11.09
# Version: 0.1
# Last-Updated:
#           By:
#     Update #: 1
# Keywords: weather_catcher parser
# Compatibility: weather_catcher_v0.1
#   depends on w3m v0.5.3
#   May work on older versions but this is not guaranteed.
#

# This file is a part of weather_catcher

# Change Log:
# - 0.1
#
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth
# Floor, Boston, MA 02110-1301, USA.
#
#

# Code:


parser_name="weather-cn"
debug "parser_name: $parser_name"

update_weather_data () {
    if [ ! $arg ]; then
        arg="www.weather.com.cn/weather/101010100.shtml"
    fi
    URL="$arg"

    # dump web page
    debug "dumping url: $URL"
    w3m -dump $URL>$weather_tmp_file

    parse_data
}

parse_data () {
    # get valid weather info section in the page
    weather_block=`awk '
/天气图例/{enable_print=1}
/周边地区明日天气/{if (enable_print) exit}
enable_print{print}
' $weather_tmp_file`
    debug "weather block:"
    debug_lines "$weather_block"

    # get location name
    LN=`echo "$weather_block" | head -1 | sed 's/天气预报.*$//'`

    # get other weather data
    weather_block=`echo "$weather_block" | sed -e '1d' -e '$d' -e '/^.\?$/d' -e '/未来4-7天天气预报/d'`
    debug "weather block[fixed]"
    debug_lines "$weather_block"
    days_count=`echo "$weather_block" | awk -v RS='星期' 'END{print NR}'`
    debug "days_count: $days_count"
    for ((i=2; i<=$days_count; i++)); do
        # the first valid record start as index 2
        daynum=$(($i-2))
        debug "future_day_$daynum"
        set_data_type "LN" $LN
        day_weather_block=`echo "$weather_block" | awk -v RS='星期' -v i=$i 'NR==i'`

        # weather info on day(maybe is disappeared)
        dayinfo=`echo "$day_weather_block" | awk -v RS='夜间' 'NR==1'`
        dayinfo=`echo "$dayinfo" | tr '\n' ' '` # skip newlines
        debug "  dayinfo#$daynum: $dayinfo"

        # weather text on day, if is a long text, it will append at
        # second line, and after parsing, it will appear as $9
        WTD=`echo "$dayinfo" | awk '{if ($(10))print $4$9; else print $4}'`
        set_data_type "WTD" $WTD

        # weather font on day
        WFD=`general_weather_text2font_cn "$WTD"`
        set_data_type "WFD" $WFD

        # high temperature
        HT=`echo "$dayinfo" | awk '{print $6}' | sed 's/^\(-\?[0-9]\+\).*$/\1/'`
        set_data_type "HT" $HT

        # wind direction on day
        WDD=`echo "$dayinfo" | awk '{print $7}'`
        set_data_type "WDD" $WDD

        # wind speed text on day
        WSTD=`echo "$dayinfo" | awk '{print $8}'`
        set_data_type "WSTD" $WSTD

        # weather info on night(maybe is disappeared)
        nightinfo=`echo "$day_weather_block" | awk -v RS='夜间' 'NR==2'`
        nightinfo=`echo "$nightinfo" | tr '\n' ' '` # skip newlines
        debug "  nightinfo#$daynum: $nightinfo"

        # weather text on night, if is a long text, it will append at
        # second line, and after parsing, it will appear as $8
        WTN=`echo "$nightinfo" | awk '{if ($8) print $2$7; else print $2}'`
        set_data_type "WTN" $WTN

        # weather font on night
        WFN=`general_weather_text2font_cn "$WTN"`
        set_data_type "WFN" $WFN

        # low temperature
        LT=`echo "$nightinfo" | awk '{print $4}' | sed 's/^\(-\?[0-9]\+\).*$/\1/'`
        set_data_type "LT" $LT

        # wind direction on night
        WDN=`echo "$nightinfo" | awk '{print $5}'`
        set_data_type "WDN" $WDN

        # wind speed text on night
        WSTN=`echo "$nightinfo" | awk '{print $6}'`
        set_data_type "WSTN" $WSTN

        write_data_types $daynum
    done
}

parser_help () {
    cat <<EOF
TODO
Argument meaning:
    The complete url which page owns weather info you expect.
    [default: http://www.weather.com.cn/weather/101010100.shtml]
Support data types:
    WF:  weather font output
    WT:  weather text
    LT:  low temperature
    HT:  high temperature
    WST: wind speed text
    LN:  location name
Support max future days: 2
Limits:
    Should only work for Chinese friends.
EOF
}

parser_version () {
    echo "version 0.1, build_20121109"
}

debug "parser load success"


#
# weather-cn.sh ends here