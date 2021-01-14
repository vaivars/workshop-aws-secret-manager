provider "aws" {

}

data "archive_file" "lambda_zip" {

    type          = "zip"
    source_file   = "./function/index.js"
    output_path   = "lambda_function.zip"
}
resource "random_password" "password" {
  length = 32
  special = true
  override_special = "_%@"
}

resource "aws_secretsmanager_secret" "workshop_lambda_very_secret_secret" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "workshop_lambda_very_secret_secret" {
  secret_id     = var.secret_name
  secret_string = random_password.password.result
}

resource "aws_s3_bucket" "main" {

  bucket = var.bucket_name
  acl    = "private"
}

resource "aws_s3_bucket_object" "s3_function" {

  bucket = aws_s3_bucket.main.id
  key     =  "lambda_function.zip"
  source = "lambda_function.zip"
}

resource "aws_s3_bucket_object" "s3_layer" {

  bucket = aws_s3_bucket.main.id
  key     =  "aws_sdk_layer.zip"
  source = "aws_sdk_layer.zip"
}

resource "aws_lambda_layer_version" "aws_sdk_layer" {
  s3_bucket = aws_s3_bucket.main.id
  s3_key = "aws_sdk_layer.zip"
  layer_name = "aws_sdk_layer"

  compatible_runtimes = ["nodejs12.x"]
}

resource "aws_lambda_function" "workshop_lambda_function" {

  function_name = var.function_name
  s3_bucket     = aws_s3_bucket.main.id
  s3_key        = "lambda_function.zip"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"
  layers        = [aws_lambda_layer_version.aws_sdk_layer.arn]
  environment {
    variables = {
      secret_name = var.secret_name
    }
  }
}
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "lambda_role" {

  name = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_secret_manager_policy" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_secret_manager_policy" {
  name = "lambda_secret_manager_policy"
  role = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_secret_manager_policy.json
}

resource "aws_api_gateway_rest_api" "apiLambda" {
  name        = var.api_gw_name
}

resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   parent_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxyMethod" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.proxyMethod.resource_id
   http_method = aws_api_gateway_method.proxyMethod.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.workshop_lambda_function.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.workshop_lambda_function.invoke_arn
}


resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   stage_name  = "test"
}


resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.workshop_lambda_function.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.apiLambda.execution_arn}/*/*"
}

output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}
