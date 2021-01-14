var AWS = require('aws-sdk'),
  region = "eu-west-1",
  secretName = process.env.secret_name,
  secret,
  decodedBinarySecret;

var client = new AWS.SecretsManager({
  region: region
});

module.exports.handler = (event, context, callback) => {

  // In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
  // See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
  // We rethrow the exception by default.

  client.getSecretValue({SecretId: secretName}, function (err, data) {
    if (err) {
      if (err.code === 'DecryptionFailureException')
        // Secrets Manager can't decrypt the protected secret text using the provided KMS key.
        // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'InternalServiceErrorException')
        // An error occurred on the server side.
        // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'InvalidParameterException')
        // You provided an invalid value for a parameter.
        // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'InvalidRequestException')
        // You provided a parameter value that is not valid for the current state of the resource.
        // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
      else if (err.code === 'ResourceNotFoundException')
        // We can't find the resource that you asked for.
        // Deal with the exception here, and/or rethrow at your discretion.
        throw err;
    } else {
      // Decrypts secret using the associated KMS CMK.
      // Depending on whether the secret is a string or binary, one of these fields will be populated.
      if ('SecretString' in data) {
        secret = data.SecretString;
      } else {
        let buff = new Buffer(data.SecretBinary, 'base64');
        decodedBinarySecret = buff.toString('ascii');
      }
    }
  });

  setTimeout(callback(
    null,
    {
      statusCode: 200,
      headers: {
        'Content-Type': 'text/html',
      },
      body: "<div style='position: relative; width: 100%; height: 100%; background: #000; font-family: Arial, sans-serif;'>" +
        "<div style='position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); background: rgba(0,0,0,0.2)'>" +
        "<h1 style='font-size: 30px; text-align: center; color: #fff'>" +
         secret +
         "</h1>"+
         "<p style='font-size: 20px; text-align: center; color: #fff'>Congratulations, your very secret secret is now accessible to the world with the power of AWS LAMBDA</p>" +
         "<img style='width: 1000px;' src='https://cdn.suwalls.com/wallpapers/meme/all-your-base-are-belong-to-us-9009-2560x1600.jpg'/>" +
         "</div>" +
         "</div>"
    }
  ), 100);

  // Use this code if you don't use the http event with the LAMBDA-PROXY integration
  // callback(null, { message: secret, event });
};