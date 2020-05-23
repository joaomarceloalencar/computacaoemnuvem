var AWS = require ('aws-sdk');

AWS.config.update({region: 'us-east-1'});

var ddb = new AWS.DynamoDB();

var params = {
   AttributesToGet: [
      "emailId"
   ],
   TableName : "phonebook_app",
   Key : {
      "contactName" : {
         "S" : "Joao Marcelo "
      },
      "contactNumber" : {
         "N": "85988370637"
      }

   }
}

ddb.getItem(params, function(err, data) {
      if (err) {
         console.log(err);
      } else {
         console.log(data);
      }
   }
); 

