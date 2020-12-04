test_list = [[2,'Discord',99999999999918263], [1,'Slack',9127312983]] 

# using sort() + lambda 
# to sort list of list 
# sort by second index 
test_list.sort(key = lambda test_list: test_list[2]) 

print ("List after sorting by 2nd element of lists : " + str(test_list)) 
