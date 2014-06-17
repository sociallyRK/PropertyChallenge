# OUTPUT:
# Your program will use the input data to perform searches for available properties.  

# Each search specifies a location and a date range.  Your program should return the 10 cheapest, nearby properties for that date range.  
# For the geographic filter, use a bounding box that is 2 degrees square in total (ie, +/- 1.0 degrees from each coordinate).  
# If a property is unavailable for any date during the range, it is not a valid result.  

# If a property has a variable price specified during the range, that variable price overrides the base nightly price.  

# The total price is the sum of the nightly prices for the entire stay.  The program should return the cheapest available properties, in order, up to a max of 10.  

# Note that properties do not need to be available on the checkout date itself, just on the day before.

# Your program should produce a file called search_results.csv.  Each row is a result for one of the given searches.  A search with 10 valid results corresponds to 10 rows.
# search_id - integer
# rank - integer
# property_id
# total_price - the total price for the stay

require 'csv'
require 'Date'

#checks to see if the date is between the beginning date and one day before end date
def date_lies_between(exclusion, beginning_date, end_date)
  return (exclusion >= beginning_date) && (exclusion < end_date)
end

#main method that filters through exclusions, price changes, and unavailable dates
def closest_properties 
calendar = CSV.read('calendar.csv')
calendar_date = []

#need to store date as a date object not a string but stay within calendar array
calendar.each do |exclusion|
  exclusion_array = []
  exclusion_array << exclusion[0]
  exclusion_array << Date.strptime(exclusion[1], "%m/%d/%y")
  exclusion_array << exclusion[2]
  exclusion_array << exclusion[3]
  calendar_date << exclusion_array
end

#downloads the searches CSV file
searches = CSV.read('searches.csv')

#downloads the properties CSV file
properties = CSV.read('properties.csv')
search_hash = {}
calendar_hash = {}

#collections all the exclusions by property
calendar_date.each do |exclusion|
  if calendar_hash[exclusion[0]] == nil
    calendar_hash[exclusion[0]] = [exclusion]
  else
    calendar_hash[exclusion[0]].push exclusion
  end
end

#solution with empty array
solution = []

#solution with filtering of exclusions, properties closest to desired location, and variants in pricing
searches.each do |search|
  properties.each do |property|
    premium = 0
    if ((property[2].to_f - search[2].to_f).abs < 1) && ((property[1].to_f - search[1].to_f).abs < 1) 
      beginning_date = DateTime.parse(search[3])
      end_date = DateTime.parse(search[4])
      lastpaid_date = end_date-1
      exclusions = []
      needs_to_be_excluded = false
      if calendar_hash[property[0]] != nil 
        calendar_hash[property[0]].each do |exclusion|
           if date_lies_between(exclusion[1], beginning_date, lastpaid_date) && exclusion[2].to_i==0
             needs_to_be_excluded = true
           elsif date_lies_between(exclusion[1], beginning_date, lastpaid_date) && exclusion[2].to_i==1
             premium += exclusion[3].to_i - property[3].to_i
           else
             #puts "Just add the property normally"
           end
        end
      end
    if !needs_to_be_excluded 
    solution.push [search[0].to_i, 1, property[0].to_i,  (lastpaid_date - beginning_date).to_i * property[3].to_i + premium]  
    end
    end
  end
end
#sorts entire solution
solution.sort_by! {|element| [element[0], element[3]]}
solution.each_index do |index|
  if index > 1 && solution[index][0] == solution[index-1][0]
    solution[index][1] = solution[index-1][1]+1
  end
end
#removes any solutions with rank > 10
solution.each_index do |index|
  if solution[index][1] > 10
    solution.splice(index)
  end
end
p solution

#saves solution to csv file
CSV.open("searchresults.csv", 'w') do |csv|
  csv << ["Index", "Rank", "Property", "Price"]
  solution.each do |row_array|
    csv << row_array
  end
end
end
closest_properties 
