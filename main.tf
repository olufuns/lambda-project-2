data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "morays_lambda_noteservice" {
  function_name = "morays-lambda-noteservice"
  role          = aws_iam_role.morays_lambda_role.arn
  runtime       = var.runtime
  handler       = "handler.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      morays_lambda_notes_table = aws_dynamodb_table.notes.name
    }
  }

}

resource "aws_dynamodb_table" "notes" {
  name         = "morays-lambda-notes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "noteId"

  attribute {
    name = "noteId"
    type = "S"
  }
}

resource "aws_apigatewayv2_api" "morays_lambda_api" {
  name          = "morays-lambda-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "morays_api_integration" {
  api_id                 = aws_apigatewayv2_api.morays_lambda_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.morays_lambda_noteservice.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.morays_lambda_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.morays_api_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.morays_lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.morays_lambda_noteservice.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.morays_lambda_api.execution_arn}/*/*"
}