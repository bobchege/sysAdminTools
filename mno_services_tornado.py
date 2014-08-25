#!/usr/bin/python

import tornado.httpserver
import tornado.ioloop
from tornadows import soaphandler
from tornadows import webservices
from tornadows import xmltypes
from tornadows import complextypes
from tornadows.soaphandler import webservice

from collections import defaultdict, OrderedDict

# from collections import OrderedDict
#from odict import OrderedDict

import logging
import sys
import MySQLdb 
#import web
import datetime
import time
import logging

class Utilities():
	def myFlog(self, message):
		remote ="/var/www/html9008/logs/SBAmnoservicesAPI.log"
                log = remote
                header = "[MNO_SERVICES] "
                today=time.strftime("%Y-%m-%d %H:%M:%S")    
                f = open(log, 'a')
                body = "[%s %s%s\n" % (today,header,message)
                f.write(body)
                f.close()
	
	
class Mno_services(soaphandler.SoapHandler):
	# initialize all the variables here
	DB_HOST="XXXXXX"
	DB_USER="XXXXXX"
	DB_PASS="XXXXXX"
	DB="XXXXXXX"
	DB_MAIN="XXXXXXX"
	#today=time.strftime("%Y-%m-%d %H:%M:%S")
	#db=MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
	#dbLink=db.cursor()
	remote ="/var/www/html9008/logs/SBAmnoservicesAPI.log";
		
	def _init_(self):
		util.myFlog("Starting the server")
		self.DB_HOST="sentinel"
		self.DB_USER="OptimusBot"
		self.DB_PASS="b00tv4@1*8"
		self.DB="airtimeTest"
		self.DB_MAIN="mnoservices"
		self.today=time.strftime("%Y-%m-%d %H:%M:%S")
		self.db=MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
		self.dbLink=db.cursor()
		self.remote ="/var/www/html9008/logs/SBAmnoservicesAPI.log"
	
	# change msisdn replace 0 with country code 
	def change_msisdn_no(msisdn,country_code):
	    msisdn_without_0 = msisdn[1:]
	    # print "msisdn_without_0 : ",msisdn_without_0
	    updated_msisdn = country_code+msisdn_without_0
	    return updated_msisdn
 
	# country code is retrieved from db using networkID 
	def retrieve_country_prefix(countryID):
	    query = "select countryCode from countryCodes where countryID = '%d' " %countryID;
	    dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
	    db = dbLink.cursor()
	    db.execute(query)
	    rw = db.fetchone()
	    num = db.rowcount
	    db.close()
	    dbLink.close()
	    country_code = rw[0]        
	    return country_code

	# msisdn test 
	def validateMSISDN(msisdn, countryID):
	    if(msisdn[0] == '0'):	# if it starts with 0 and not the country code - replace 0 with country code retrieved from db
		country_code = retrieve_country_prefix(countryID)
		# print "country_code : ",country_code
		updated_msisdn = change_msisdn_no(msisdn,country_code)
	    else :
		    updated_msisdn = msisdn
	    return updated_msisdn   


	def nesteddict(): 
	  return defaultdict(nesteddict)

	def createResponse(ns_request,status,payload):
	    response = {}	
	    response = nesteddict()
	    
	    if (ns_request == "ns1:PostResponse" ):
		response['ns1:PostResponse']['status'] = status
		response['ns1:PostResponse']['payload']= payload
	    
	    elif (ns_request == "ns1:QueryResponse" ):
		response['ns1:queryResponse']['status'] = status
		response['ns1:queryResponse']['payload']= payload
	    return response


      
	def isValidReferenceIDPost(bankRefID,merchantTypeID, dbName,tableName,partnerID,bankTableName):
	
		util.myFlog("%s ################## isValidReferenceIDPost merchantTypeID : %s ################\n" % (bankRefID,merchantTypeID))
	    	#INITIALIZE THE RESPONSE VARIABLES
		response = {}
	     	if(merchantTypeID == 1):
	     	# line to be replaced by the get bankID method
	     	     bankID = getBankID(partnerID,dbName,bankRefID,bankTableName)
	     	     
	     	     if(bankID>0):
	     	     	     util.myFlog("%s Contructing query for AirtimeTopup" % bankRefID)	
		     	     query = "select requestID from %s.%s where bankID = '%s' and bankTransactionID = '%s'" %(dbName,tableName,bankID,bankRefID);
		     	     dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
		     	     db = dbLink.cursor()
		     	     db.execute(query)
		     	     db.fetchall
		     	     num = db.rowcount
		     	     db.close()
		  	     dbLink.close()
		     	     if(num > 0):
		     	     	      response['validReferenceID'] = -1
		     	     	      response['state']	= -1    
		     	     	      util.myFlog("%s *********** invalid referenceid ***********" % bankRefID)
		     	     else:
	     	     		      response['validReferenceID'] = bankRefID
				      response['state'] = 99	
				      util.myFlog("%s VALIDATION SUCCESSFULL STATE %s" % (bankRefID,response['state']))	
	     	     else: 
	     	     
	     	     	    response['validReferenceID'] = -1;
			    response['state'] = -1;
	     	     	     
	     	else:
	     	   util.myFlog("%s Contructing query for Mpesa topup" % bankRefID)
	     	   query = "select requestID from %s.%s where uniqueID = '%s'" %(dbName,tableName,bankRefID)	
		   dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
		   db = dbLink.cursor()
		   db.execute(query)
		   #db.fetchall
		   num = db.rowcount     	
		   db.close()
		   dbLink.close()
		   
		   if(num > 0):
		     	     	      response['validReferenceID'] = -1
		     	     	      response['state']	= -1    
		     	     	      util.myFlog("%s *********** invalid referenceid ***********" % bankRefID)
		   else:
	     	     		      response['validReferenceID'] = bankRefID
				      response['state'] = 99	
	       			      util.myFlog("%s VALIDATION SUCCESSFULL STATE %s" % (bankRefID,response['state']))	
		  
		return response
		
		
	def isValidReferenceIDQuery(referenceID,partnerID):
	
		response = {}
		util.myFlog("%s ######################## isValidReferenceIDQuery ###################### "% referenceID)
		query = "select merchantID from requestLog where bankRefID ='%s' and partnerID ='%s'" %(referenceID,partnerID)
		util.myFlog("%s  The query to validate the referenceID %s "% (referenceID,query))
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
		db = dbLink.cursor()
		db.execute(query)
		rw = db.fetchone()
		num = db.rowcount
	
		util.myFlog("%s  The row count is: %d "% (referenceID,num))
		if(num > 0):
		     response['validReferenceID'] = 99
		     response['merchantID'] = rw[0]
		     util.myFlog("%s The referenceID is valid %s !!!!! :-) " %(referenceID,response['merchantID']))
		else:
		     response['validReferenceID'] = -1
		     response['merchantID'] = -1
		     util.myFlog("%s ******  INVALID REFERENCEID ******\n" % referenceID)

		return response	


	def isValidMerchantID(merchantID,bankRefID):
		
		
		util.myFlog("%s ################## isValidMerchantID mechantID : %s ################\n" % (bankRefID,merchantID))
		
		getdbName = "select dbName,tableName,merchantTypeID,extraData,bankTableName from %s.merchants where merchantID = '%s' and isActive =1" % (DB_MAIN,merchantID)
		util.myFlog(getdbName)
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
		db = dbLink.cursor()
		db.execute(getdbName)
		rw = db.fetchone()
		num = db.rowcount
		dbName = {}
		util.myFlog("%s Fetching the DBNAME %s ..mysql_error() \n" %(bankRefID,getdbName))	
	
		if(num > 0):
			dbName['dbName'] = rw[0]
			dbName['tableName']  = rw[1]
			dbName['merchantTypeID'] = rw[2]
			dbName['networkID'] = rw[3]
			dbName['bankTableName'] = rw[4]
			util.myFlog("%s Found DBNAME: %s \n" %(bankRefID,dbName['dbName']))
		else:	
			dbName['dbName'] = "NULL"
			dbName['tableName']  = "NULL"
			dbName['merchantTypeID'] = "NULL" 
			dbName['networkID'] = "NULL"
			dbName['bankTableName'] = "NULL"
			util.myFlog(" %s ******* DBNAME NOT FOUND ********* ..\n" % bankRefID)	
	
		return dbName


	def isValidCredentials(accessName,password):
	
		util.myFlog("################## isValidCredentials ################\n")	
	
		getCredentialsID = "select partners.partnerID,credentialID from credentials inner join partners on credentials.partnerID = partners.partnerID where accessName = '%s' and accessKey = md5('%s') and isActive =1" %(accessName,password)
		util.myFlog("Constructing the query to validate credentials %s" % (getCredentialsID))
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
		db = dbLink.cursor()
		db.execute(getCredentialsID)
		rw = db.fetchone()
		num = db.rowcount
		validCredentials = {}
	
		util.myFlog("Fetching credentials : the row count is %d ..%s." % (num,rw))
	
		if(num > 0):
		
			validCredentials = {}
			while rw is not None:
				util.myFlog("Validation in loop")
				validCredentials['partnerID'] = rw[0]
				validCredentials['clientID'] = rw[1]
				rw = db.fetchone()
			   
			util.myFlog("Validation Successful")
		else:
			validCredentials['partnerID']= 0
			validCredentials['clientID']= 0	
			util.myFlog(" ******* VALIDATION WAS UNSUCCESSFUL ******")
			
		
		return validCredentials
	
	
	
	
	def getAmount(amount,merchantID,bankRefID):
	
		util.myFlog("%s ########################## getAmount #################################### \n" % bankRefID)
	
		query = "select divisor from merchants where merchantID=%s" %(merchantID)
		util.myFlog("%s The query %s" % (bankRefID,query))
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
		db = dbLink.cursor()
		db.execute(getdbName)
		rw = db.fetchone
		num = db.rowcount
	
		util.myFlog(" The Divisor: %d" % (bankRefID,denominator))
		denominator = rw[0]
		amount = amount/denominator
	
		util.myFlog("%s The final amount ------ %d" % (bankRefID,amount))
	
		return amount
	
	
	
	def getTopUpFinalStatus(requestID,bankRefID,dbName,tableName,bankID):	

		util.myFlog("%s ################## getTopUpFinalStatus ################\n" % bankRefID)
		util.myFlog("%s :bankRefID C360UNIQUEID : %d" % (bankRefID,int(requestID)))
		status = {}
	
		if(bankRefID !="" and requestID != ""):
			 if (requestID == '0'):
			     sql = "select status, statusMessage from %s.%s where banktransactionID = '%s' and bankID = '%s'" %(dbName,tableName,bankRefID,bankID);
			 else:
			     sql = "select status, statusMessage from %s.%s where banktransactionID = '%s' and requestID = %d and bankID = '%s'" %(dbName,tableName,bankRefID,int(requestID),bankID);
			 util.myFlog(sql)

			 dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
			 db = dbLink.cursor()
			 db.execute(sql)
			 rw = db.fetchone()
			 num = db.rowcount
			 util.myFlog("%s get final stat TOPUP- %s" % (bankRefID,sql))
			 
			 if(num > 0):
			 	 
				  
			    	   
			     	   status['status'] = rw[0];
				   status['statusMessage'] = rw[1];
		              	   util.myFlog("%s ### TopUp query State : %s Message : %s ####" % (bankRefID,status['status'],status['statusMessage']))
			     

		         else:
				   status['status'] =203;
			  	   status['statusMessage'] = None;
			   	   util.myFlog("%s ********** TOPUP QUERY STATE : %s Message : %s REFID:bankRefID : C360ID : %s ***********" %(bankRefID,status['status'],status['statusMessage'],requestID));
		     		
		else:
			 status['status'] =203;
			 status['statusMessage'] = None;
			 util.myFlog("%s **************** INVALID ENTRIES ANALYSIS REFID:bankRefID : C360ID : %s *****************" % (bankRefID,requestID))
	
	

		return status
	

	def getMpesaFinalStatus(requestID,bankRefID,dbName,tableName,partnerID):
	
		util.myFlog("%s ################## getMpesaFinalStatus  ################\n" % bankRefID );
		status = {}
		util.myFlog("%s BANKREID : bankRefID C360UNIQUEID : %d" % (bankRefID,int(requestID)) );
	
		if(bankRefID !="" and requestID != ""):
			 sql = "select status, statusMessage from %s.%s where requestID = %d and uniqueID ='%s'" %(dbName,tableName,int(requestID),bankRefID)
			 dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,dbName)
			 db = dbLink.cursor()
			 db.execute(sql)
			 rw = db.fetchone()
			 num = db.rowcount
			 util.myFlog("%s get final stat TOPUP- %s" % (bankRefID,sql))
			 if(num > 0):
			 	 
				  
			    	   
			     	   status['status'] = rw[0];
				   status['statusMessage'] = rw[1];
		              	   util.myFlog("%s Final status was Successful -- " % bankRefID)
			     

		         else:
				   status['status'] =203;
			  	   status['statusMessage'] =None;
			   	   util.myFlog("%s ********* FINAL STATUS WAS UNSUCCESSFUL --  ********* "% bankRefID);
		else:
			 status['status'] =203;
			 status['statusMessage'] =None;
			 util.myFlog(remote,"%s **************** INVALID ENTRIES ANALYSIS REFID:bankRefID : C360ID : %d *****************"% (bankRefID,requestID))
	

		return status
	
	

	def getBankID(partnerID,dbName,referenceID,bankTableName):

		util.myFlog("%s ################## getBankID ################\n" % referenceID);	
	
		bankID = 0
		util.myFlog("%s The datails partnerID : %d  DBNAME : %s" % (referenceID,partnerID,dbName))
	
		getBankID = "select bankID from %s.%s where partnerID = %s" %(dbName,bankTableName,partnerID);
		util.myFlog(getBankID)	
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
		db = dbLink.cursor()
		db.execute(getBankID)
		rw = db.fetchone()
		num = db.rowcount
	
		if(num > 0):
		  
		      bankID = rw[0];
		      util.myFlog("%s BankID Has been Found : %d" % (referenceID,bankID));
		      
		else:
		      bankID = -1;
		      util.myFlog("%s ****** BANKID WAS NOT FOUND ******\n" % referenceID);
		  
		return bankID	






	def getPrefferedMethod(partnerID,dbName,bankTableName,bankrefID):

		util.myFlog("%s ################## getPrefferedMethod %s ################\n" % (bankrefID,dbName))
		getprefferedMethod = "select prefferedMethod from %s.%s where partnerID = %s" % (dbName,bankTableName,partnerID)
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
		db = dbLink.cursor()
		db.execute(getprefferedMethod)
		rw = db.fetchone()
		num = db.rowcount
		util.myFlog("%s Fetching prefered Method . " % bankrefID)
	
		if(num > 0):
	
		      
		      prefferedMethod = rw[0];
		      util.myFlog("%s Found a prefered Method :%d " % (bankrefID,prefferedMethod))	
		      
		else:
		      prefferedMethod = 0;
		      util.myFlog("%s****** PREFERED METHOD NOT FOUND ******" %(bankrefID))
		  
		return prefferedMethod
	
	
	
	

	def logTopUp(bankRefID,bankID,AMOUNT,MSISDN,requestLogID,referenceID,prefferedMethod,dbName,networkID,tableName,merchantID):
		#if networkID == "":
		  #networkID = "1"

		util.myFlog("%s ##################### logTopUp : #####################\n " % bankRefID);
		util.myFlog("The Insert has dbname %s tablename %s bankID %d AMOUNT %d MSISDN %d requestLogID %d referenceID %s prefferedMethod %d networkID %s bankRefID %s "% (dbName,tableName,bankID,int(AMOUNT),int(MSISDN),int(requestLogID),referenceID,int(prefferedMethod),networkID,bankRefID));
	#	util.myFlog("The Insert has %s, %s, %d,%d,'%s',%d,'%s', %d,'%s',%d\n" % (dbName,tableName,bankID,AMOUNT,MSISDN,requestLogID,referenceID,prefferedMethod,requestLogID,networkID));
		#logVRquery = "insert into %s.%s(bankID,amount,MSISDN,refID,bankTransactionID,dateCreated,prefferedMethod,requestLogID,networkID) values(%d,%d,%d,%d,'%s','now()',%d,%d,%d)" % (dbName,tableName,int(bankID),int(AMOUNT),int(MSISDN),int(requestLogID),referenceID,int(prefferedMethod),requestLogID,int(networkID))
		logVRquery = "insert into %s . %s (bankID,amount,MSISDN,refID,bankTransactionID,dateCreated,prefferedMethod,requestLogID,networkID,merchantID) values('%d','%d','%s','%d','%s',now(),'%d','%d','%d','%d')" % (dbName,tableName,int(bankID),int(AMOUNT),MSISDN,int(requestLogID),referenceID,int(prefferedMethod),int(requestLogID),1,int(merchantID))
	
		util.myFlog("%s The topup Log: %s" %(bankRefID,logVRquery))

		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
		db = dbLink.cursor()
		db.execute(logVRquery)
		dbLink.commit()
		VRTranID = db.lastrowid
		status = {}
		if(VRTranID > 0):
			 status['status'] = 1 #successfully logged in VRtRX table
			 status['requestID'] = VRTranID;	
			 util.myFlog("%s referenceID topup Log was successful ......" % bankRefID)
		else:
			 status['status'] = 2 #not logged in VRtRX table
			 status['requestID'] = -1;
			 util.myFlog("%s ******  topup Log was successful ******" % bankRefID)
		return status

	
	# msisdn test 
	def validateMSISDN(msisdn, country_code):
	    if(msisdn[0] == '0'):	# if it starts with 0 and not the country code - replace 0 with country code retrieved from db
		# country_code = retrieve_country_prefix(1)
		print "country_code : ",country_code
		updated_msisdn = change_msisdn_no(msisdn,country_code)

	    else :
		    updated_msisdn = msisdn
	    return updated_msisdn   	
	
	# change msisdn replace 0 with country code 
	def change_msisdn_no(msisdn,country_code):
	    msisdn_without_0 = msisdn[1:]
	    print "msisdn_without_0 : ",msisdn_without_0
	    updated_msisdn = country_code+msisdn_without_0
	    print "updated_msisdn : ",updated_msisdn
	    util.myFlog("%s ##################### Updated MSISDN #####################\n " % updated_msisdn)
	    return updated_msisdn
	    	


	def prepMSISDN(MSISDN,clientID,bankRefID, merchantID):

		util.myFlog("%s ##################### prepMSISDN : bankRefID #####################\n " % merchantID)
	
		# FetchCode = "Select code from credentials where appendCode=1 and credentialID=%d" % (clientID)
		FetchCode = "select countryCODE from countryCodes where merchantID=%s" % (merchantID)
		# select countryCODE from countryCodes where merchantID = '26'
	
		util.myFlog("Fetch country code Query %s "% FetchCode)
	
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
		db = dbLink.cursor()
		db.execute(FetchCode)
		rw = db.fetchone()
		num = db.rowcount
	
		temp = rw[0]
	
		#if(num > 0):
		    #temp =rw[0]
		
		MSISDN = validateMSISDN(MSISDN, temp)
		return MSISDN	
	
	
	def logMpesa(MSISDN,requestLogID,AMOUNT,dbName,tableName,bankRefID):

		util.myFlog("%s ##################### logMpesa : bankRefID #####################\n " % bankRefID);
		logVRquery = "insert into %s.%s(amount,SOURCE_MSISDN,DEST_MSISDN,uniqueID,dateCreated,requestLogID) values(%d,%s,%s,%s,now(),%d)" %(dbName,tableName,AMOUNT,MSISDN,MSISDN,bankRefID,requestLogID)
		dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB)
		db = dbLink.cursor()
		db.execute(logVRquery)
		dbLink.commit()
		VRTranID = db.lstrowid
	
		if(VRTranID > 0):
			 status['status'] = 1 #successfully logged in VRtRX table
			 status['requestID'] = VRTranID;	
			 util.myFlog("%s referenceID topup Log was successful ......" % bankRefID)
		else:
			 status['status'] = 2 #not logged in VRtRX table
			 status['requestID'] = -1;
			 util.myFlog("%s ******  topup Log was successful ******" % bankRefID);
	
		return status

	def myFlog(self, message):
		
		log = self.remote
		header = "[MNO_SERVICES] "
		today=time.strftime("%Y-%m-%d %H:%M:%S")    
		f = open(log, 'a')
		body = "[%s %s%s\n" % (today,header,message)
		f.write(body)
		f.close()
		
	def prepareStatusResponse(status,bankRefID,c360uniqueID):
		
		util.myFlog("%s ##################### prepareStatusResponse ########################" % bankRefID)
		responseStatus = {}
		message = ''
		stat = ''
		util.myFlog("%s status: %s uniqueID: %s" % (bankRefID,status,c360uniqueID))
	
		if(int(status) >= 0):
		    # in future this should be configurable from the db  
		                          
		    stat = int(status);
		    if(stat == 0):stat= 0;message = 'Pending';
		    if(stat == 50):stat = 50;  message = 'In Progress';
		    if(stat == 100):stat = 100; message = 'Forwarded request to merchant for action';
		    if(stat == 110):stat= 110;message = 'Invalid ReferenceID';
		    if(stat == 111):stat = 111; message = 'Merchant is Inactive. Failed';
		    if(stat == 102):stat = 102; message = 'Scheduled for re-processing';
		    if(stat == 104):stat = 104;  message = 'Request forwarded to merchant for action type 2 to be treated as 100';
		    if(stat == 103):stat = 103;  message = 'Response timed out. Transaction should not be reversed';
		    if(stat == 105):stat = 105; message = 'Request timed out. Transaction should be reversed';
		    if(stat == 200 or stat == 1): stat = 200; message = 'Successful';
		    if(stat == 202 or stat == 3):stat = 202; message = 'Failed';
		    if(stat == 203):stat = 203;  message = 'Invalid C360UNIQUEID or REFERENCEID ';
		    
		    util.myFlog("%s  The status : %s DESCRIPTION: %s" % (bankRefID,stat,message))	

		    responseStatus["REFERENCEID"] = bankRefID
		    responseStatus["C360UNIQUEID"] = c360uniqueID
		    responseStatus["STATUSCODE"] = stat
		    responseStatus["DESCRIPTION"]= message
		    
		else:
		    message = 'Reference ID not found. Failed'
		    status = 203
				        
		    responseStatus["REFERENCEID"] = bankRefID
		    responseStatus["C360UNIQUEID"] = c360uniqueID
		    responseStatus["STATUSCODE"] = "203"
		    responseStatus["DESCRIPTION"]= message
		    util.myFlog("%s  The status : %s DESCRIPTION: %s" % (bankRefID,status,message))
		
		util.myFlog("%s  The response from prep: %s" % (bankRefID,responseStatus)) 
		
		return responseStatus        
        
	#@webservice(_params={},_returns=createResponse)
	def postRequest(requestData):
	
		util.myFlog("//////////////////////////////// postRequest ////////////////////////////////\n");	
		credentials = {}
		requests = {}

		util.myFlog("The Payload: %s\n" % requestData);
	
		for item in requestData:	
			util.myFlog("Am inside the for loop");
			credentials = requestData['credentials']
		
		util.myFlog("Just assisgned the Credentials payload %s" % credentials)
		requests = requestData['payload']
	
		username = credentials['username']
		password = credentials['password']
	
		validCredentials = isValidCredentials(username,password)	
		statusResponse = {}
		response = {}
	
		if(validCredentials['partnerID'] > 0):
		  
		     partnerID = validCredentials['partnerID']
		     clientID = validCredentials["clientID"]
		     statusResponse['status'] = 100
		     statusResponse['description'] = 'OK'
		     # statusResponse['date'] = today
		     
		     util.myFlog("PARRRRRRRRTNER ID :%s " % partnerID);	
		     
		     #loo thru the payload dictionary 
	   
		     # for record in requests:	
		     util.myFlog("PARRRRRRRRTNER ID :%s " % requests)
		     MSISDN = requests['MSISDN']
		     bankRefID = requests['REFERENCEID']	     
		     merchantID = requests['MERCHANTID']	     
		     MSISDN = prepMSISDN(MSISDN,clientID,bankRefID,merchantID)
		     narration = requests['NARRATION']
		     currency = requests['CURRENCY']
		     AMOUNT = requests['AMOUNT']
		     beneficiaryName = requests['BENEFICIARYNAME']
		     beneficiaryID = requests['BENEFICIARYID']
		     
		     util.myFlog("%s *** MSISDN : %s | AMOUNT : %s| bankRefID : %s | MERCHANTID : %s| NARRATION : %s| CURRENCY : %s| beneficiaryName : %s| beneficiaryID : %s ***" % (bankRefID,MSISDN,AMOUNT,bankRefID, merchantID,narration,currency,beneficiaryName,beneficiaryID));
			  
		     merchantRes = isValidMerchantID(merchantID,bankRefID)
		     
		     if(merchantRes['dbName']!= "NULL"):
		
			merchantTypeID = merchantRes['merchantTypeID']
			dbName = merchantRes['dbName']
			tableName = merchantRes['tableName']
			networkID = merchantRes['networkID']
			bankTableName = merchantRes['bankTableName']
		
			util.myFlog("%s  :: NETWORKID - %s" % (bankRefID,networkID))
			 
			validMSISDN = 1 #isValidMobileNo(MSISDN)
		
		        util.myFlog("%s  :: validMSISDN - %d " % (bankRefID,validMSISDN))
		        
		        if(validMSISDN > 0):
		            #/*validate bankRefID from external system*/
		            
			    res = isValidReferenceIDPost(bankRefID,merchantTypeID, dbName,tableName,partnerID,bankTableName)
			    validReferenceID = res['validReferenceID']
			    state = res['state'] 	
			    
			    util.myFlog("%s  The state After reference Validation  : $$$$$$$$$$$$$$$$$$ %s " % (bankRefID,state))
			    
			    if(state > 0): 
			     

				util.myFlog("Oh Dear what can the matter be?")	
				#util.myFlog("The Parameters are: %d,%s,%d,'%s',%d,'%s','%s','%s',%d
				logPartnerrequest = "insert into requestLog(partnerID,MSISDN,amount,bankRefID,merchantID,narration,currency,beneficiaryName,beneficiaryID,dateCreated) values ('%d','%s',%d,'%s','%d','%s','%s','%s','%d',now())" % (int(partnerID),MSISDN,int(AMOUNT),bankRefID,int(merchantID),narration,currency,beneficiaryName,int(beneficiaryID))
				util.myFlog("John is so long at the fair!")	
				util.myFlog("%s  :: logPartnerrequest insert query %s" % (bankRefID,logPartnerrequest))										  	
				dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
				db = dbLink.cursor()
				db.execute(logPartnerrequest)
				dbLink.commit()
				dbLink.insert_id()
				requestLogID = db.lastrowid
			
				util.myFlog("%s:: requestLogID - %d" % (bankRefID,requestLogID))
			
				if(requestLogID > 0):
			
				    if(merchantTypeID == 1):
				    
					bankID = getBankID(partnerID,dbName,bankRefID,bankTableName)
	  		   		util.myFlog("%s  bankID is %d and dbName is %s" % (bankRefID,bankID,dbName))
	  		   		
	  		   		if(bankID > 0):
	  		   		
	  			 		prefferedMethod = getPrefferedMethod(partnerID,dbName,bankTableName,bankRefID)
	  			                util.myFlog("%s  preferred method is %d." % (bankRefID,prefferedMethod))
						status = logTopUp(bankRefID,bankID,AMOUNT,MSISDN,requestLogID,bankRefID,prefferedMethod,dbName,networkID,tableName,merchantID)
				
					else:

						status = 3 #no bankID found  
				                upd = "update requestLog set status =$status,dbName = '%s' where requestLogID = $requestLogID limit 1" %(dbName)                  
		           			message = 'Request not logged.Failed.';
						status = 112;
						out=0;
						resultStatus = {}
						resultStatus['REFERENCEID'] = bankRefID
						resultStatus['C360UNIQUEID'] = out
						resultStatus['STATUSCODE'] = status
						resultStatus['DESCRIPTION'] = message 
					
					    	response = resultStatus       

						util.myFlog("%s  ****** Request not logged.No bankID found. Failed ******\n" % bankRefID); 
										
					
				    else: #mpesa
				    
					util.myFlog("%s  THE MPESA SECTION LOG INITIATION  : bankRefID" % bankRefID)	
					status = logMpesa(MSISDN,requestLogID,AMOUNT,dbName,tableName,bankRefID)
				
				
				    upd = "update requestLog set status = '%s', dbName = '%s' where requestLogID = %d limit 1" %(status['status'],dbName,requestLogID)
			  	    
			  	    dbLink = MySQLdb.connect(DB_HOST,DB_USER,DB_PASS,DB_MAIN)
				    db = dbLink.cursor()
				    db.execute(upd)
				    dbLink.commit()
				    u = db.lastrowid
				    util.myFlog(" Updating the requestLog : $upd");
				    if(u >=0) :
				
				      remote = 'This is me'	
				      util.myFlog("%s  RequestLog update successful for $MSISDN  for unique requestLogID -$requestLogID" % bankRefID);
			
										
				    if(status['status']==1): 
				   
				   
					   requestID = status['requestID']	
					   message = "Request succesfully logged."
					   status = 113
					   out= requestID
					   
					   resultStatus = {}
					   resultStatus['REFERENCEID'] = bankRefID
					   resultStatus['C360UNIQUEID'] = out
					   resultStatus['STATUSCODE'] = status
					   resultStatus['DESCRIPTION'] = message 
					
					   response = resultStatus   						      
					   
					   util.myFlog("%s  ### The was Request succesfully logged.###\n" % bankRefID);

				    else:
					   message = 'Request not fully logged. Failed'
					   status = 112
					   out=0
					   resultStatus = {}
					   resultStatus['REFERENCEID'] = bankRefID
					   resultStatus['C360UNIQUEID'] = out
					   resultStatus['STATUSCODE'] = status
					   resultStatus['DESCRIPTION'] = message 
					
					   response = resultStatus   	
				 	   
					   util.myFlog("%s  ****** REQUEST NOT FULLY LOGGED. Failed ******\n" % bankRefID);

					

				else:
			
				    message = 'Failed to Log Request. Failed'
				    status = 112
				    out=0
				    
				    resultStatus = {}
				    resultStatus['REFERENCEID'] = bankRefID
				    resultStatus['C360UNIQUEID'] = out
				    resultStatus['STATUSCODE'] = status
				    resultStatus['DESCRIPTION'] = message 
					
				    response = resultStatus   
				    util.myFlog("%s ****** Failed to Log Request. Failed ******\n" % bankRefID);
				
			
			
			
			    else:
			    	#duplicate referenceID from unique system
						    
				message = 'Duplicate reference ID. Failed'
				status = 110
				out=0
				
				resultStatus = {}
				resultStatus['REFERENCEID'] = bankRefID
				resultStatus['C360UNIQUEID'] = out
				resultStatus['STATUSCODE'] = status
				resultStatus['DESCRIPTION'] = message 
					
				response = resultStatus   
				util.myFlog("%s ****** Duplicate reference ID. Failed ******\n" % bankRefID);
			    
		        else:
		            #// invalid MSISDN
			    message = 'Invalid mobile number. Failed'
			    status = 108
			    out=0
			    resultStatus = {}
			    resultStatus['REFERENCEID'] = bankRefID
			    resultStatus['C360UNIQUEID'] = out
			    resultStatus['STATUSCODE'] = status
			    resultStatus['DESCRIPTION'] = message 
			    

			    util.myFlog("%s ****** Invalid mobile number. Failed ******\n"% bankRefID)
		        
		        
		     else:
			#invalid merchantID from unique system
			message = 'Merchant is Inactive. Failed'
			status = 111
			out=0
			resultStatus = {}
			resultStatus['REFERENCEID'] = bankRefID
			resultStatus['C360UNIQUEID'] = out
			resultStatus['STATUSCODE'] = status
			resultStatus['DESCRIPTION'] = message 
				
			util.myFlog("%s ****** Invalid merchantID. Failed ******\n" % bankRefID)
		else:  
		     statusResponse['status'] = '101'
		     statusResponse['description'] = 'Invalid Credentials'
		     # statusResponse['date'] = today
		     
		util.myFlog("The response Detail : %s " % createResponse("ns1:PostResponse",statusResponse,response))
	
		return createResponse("ns1:PostResponse",statusResponse,response)

class payload(complextypes.ComplexType):
        C360UNIQUEID  = complextypes.StringProperty()
        REFERENCEID  = complextypes.StringProperty()
        MERCHANTID  = complextypes.StringProperty()
        
class credentials(complextypes.ComplexType):
	username = str
	password = str 
	
class input_data(complextypes.ComplexType):
        credentials = payload
	
class queryStatus(soaphandler.SoapHandler):
		@webservice(_params=input_data, _returns= [{'status':[{'status':str,'description':str}]}, {'payload':[{'REFERENCEID':str,'C360UNIQUEID':str,'STATUSCODE': str,'DESCRIPTION': str}]}])
    				
		def queryStatus(self, requestData):
			print 'started....'
			for arg in sys.argv:
				print 'printing'
				print arg
			util = Utilities()
			util.myFlog("########################### queryStatus ####################################\n")
	
			credentials = {}
			requests = {}
			util.myFlog("The Payload: %s\n" % type(requestData))
			util.myFlog("The Payload: %s\n" % str(requestData))	
			
			for item in requestData:	
				util.myFlog("Am inside the for loop");
				credentials = requestData['credentials']
		
			util.myFlog("Just assisgned the Credentials payload %s" % credentials)
			requests = requestData['payload']
	
			username = credentials['username']
			password = credentials['password']
	
			validCredentials = isValidCredentials(username,password)	
			statusResponse = {}
			status = ""
			response = {}
			util.myFlog("The Query Detail : %s " % requests);
		
		
			if(validCredentials['partnerID'] > 0):
			  
			     partnerID = validCredentials['partnerID']
			     clientID = validCredentials["clientID"]
			     statusResponse['status'] = 100
			     statusResponse['description'] = 'OK'
			     # statusResponse['date'] = today
			     
			     util.myFlog("PARRRRRRRRTNER ID :%s " % partnerID)
			     
			     c360uniqueID = requests['C360UNIQUEID']
			     bankRefID = requests['REFERENCEID']
			     merchantID = requests['MERCHANTID']
			     
			     """ check if merchantID is set"""
			     
			     merchantRes = isValidMerchantID(merchantID,bankRefID)   
			     merchantTypeID = merchantRes['merchantTypeID']
			     tableName = merchantRes['tableName']
			     dbName = merchantRes['dbName']
			     bankTableName = merchantRes['bankTableName']
			     
			     if(merchantRes['dbName']!= "NULL"):
			     	 
			     	 """Validate the referenceID"""	
			     	 
			     	 isValidReferenceResponse = isValidReferenceIDQuery(bankRefID,partnerID)
			     	 merchantID = isValidReferenceResponse['merchantID']
				 isvalidRef = isValidReferenceResponse['validReferenceID']
				 
				 if(isvalidRef > 0):
				     util.myFlog("%s Validated the referenceID" % bankRefID)	
				     """Determine which merchant is being queried"""
				     
				     if(merchantTypeID == 1):
				     
				       	    util.myFlog("%s CASE: Airtime TOPUP" % bankRefID)	
					    util.myFlog("partnerID: %s dbName: %s BankRefID: %s bankTableName: %s " %(partnerID,dbName,bankRefID,bankTableName))
				       	    bankID = getBankID(partnerID,dbName,bankRefID,bankTableName)
				       	    
				       	    if(bankID > 0):
				       	    
				       	    	util.myFlog("%s  BankRefID : bankRefID" % bankRefID)
						statusFinal = getTopUpFinalStatus(c360uniqueID,bankRefID,dbName,tableName,bankID)
						util.myFlog("%s  ################ Airtime status %s" % (bankRefID,statusFinal['status']))
						status = statusFinal['status']
					    else:
						"""This is an invalid referenceID"""
						status = 203
						
								 
					
				     elif(merchantTypeID == 1):
					    util.myFlog("%s CASE: Mpesa TOPUP" % bankRefID)
					    
					    util.myFlog("%s  TableName : %s , dbname : %s" %(bankRefID,dbName,tableName))
				            statusFinal = getMpesaFinalStatus(c360uniqueID,bankRefID,dbName,tableName,partnerID);
					    util.myFlog("%s  ################ mpesa status %s" % (bankRefID,statusFinal['status']))
					    status = statusFinal['status']
				     else:
					    status = "111"
				 else:
				      status = "110"	
				 
			     	 
			     else:
				   status = "111"
				   
			     """Prepare a response payload below""" 
			     util.myFlog("%s The response is here: status %s " % (bankRefID,status))     
			     response = prepareStatusResponse(status,bankRefID,c360uniqueID)
			else:
			     statusResponse['status'] = '101'
			     statusResponse['description'] = 'Invalid Credentials'
			     # statusResponse['date'] = today
		
	
			return createResponse("ns1:QueryResponse",statusResponse,response)	
if __name__ == '__main__':
	#service = [('Mno_services',Mno_services)]
	service = [('queryStatus',queryStatus)]
	ws = webservices.WebService(service)
	application = tornado.httpserver.HTTPServer(ws)
	application.listen(9008)
	tornado.ioloop.IOLoop.instance().start()

	print "Starting server..."
	print "Server is now up and tunning..."   
