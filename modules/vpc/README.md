<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.vpc_flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.vpc_flow_log_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vpc_flow_log_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_rule.public_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_ingress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_route.app_nat_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.management_nat_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.web](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.db](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.management](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.dynamodb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_app_subnet_offsets"></a> [app\_subnet\_offsets](#input\_app\_subnet\_offsets) | アプリ層サブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト | `list(number)` | <pre>[<br/>  11,<br/>  12<br/>]</pre> | no |
| <a name="input_azs"></a> [azs](#input\_azs) | 使用するアベイラビリティゾーンのリスト (例: ['ap-northeast-1a', 'ap-northeast-1c']) | `list(string)` | n/a | yes |
| <a name="input_db_subnet_offsets"></a> [db\_subnet\_offsets](#input\_db\_subnet\_offsets) | DB層サブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト | `list(number)` | <pre>[<br/>  21,<br/>  22<br/>]</pre> | no |
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | EKSクラスター名。enable\_eks=trueの場合に必須（kubernetes.io/cluster/{name}タグに使用） | `string` | `""` | no |
| <a name="input_enable_dynamodb_endpoint"></a> [enable\_dynamodb\_endpoint](#input\_enable\_dynamodb\_endpoint) | DynamoDBゲートウェイエンドポイントを作成するかどうか | `bool` | `false` | no |
| <a name="input_enable_eks"></a> [enable\_eks](#input\_enable\_eks) | EKS用のサブネットタグを付与するかどうか。EKSクラスターを作成する場合はtrueにする | `bool` | `false` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | NAT Gatewayを作成し、プライベートサブネットからインターネットへの通信を可能にするか | `bool` | `false` | no |
| <a name="input_enable_s3_endpoint"></a> [enable\_s3\_endpoint](#input\_enable\_s3\_endpoint) | S3ゲートウェイエンドポイントを作成するかどうか | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | 実行環境名 (例: dev, stg, prd) | `string` | n/a | yes |
| <a name="input_flow_log_retention_days"></a> [flow\_log\_retention\_days](#input\_flow\_log\_retention\_days) | VPCフローログ(CloudWatch Logs)の保持日数 | `number` | `7` | no |
| <a name="input_management_subnet_offsets"></a> [management\_subnet\_offsets](#input\_management\_subnet\_offsets) | 管理層サブネットのOffsetリスト。踏み台・監視・CI/CDランナー等に使用。不要な場合は [] を指定（NAT GW経由でインターネットに接続） | `list(number)` | `[]` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | 可用性を高めるため、各AZに1つずつNAT Gatewayを作成するか | `bool` | `false` | no |
| <a name="input_project"></a> [project](#input\_project) | プロジェクト名 (リソース識別用) | `string` | n/a | yes |
| <a name="input_public_subnet_offsets"></a> [public\_subnet\_offsets](#input\_public\_subnet\_offsets) | パブリックサブネットを cidrsubnet 関数で計算する際の第3引数(インデックス)のリスト | `list(number)` | <pre>[<br/>  1,<br/>  2<br/>]</pre> | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | すべてのプライベートサブネットで1つのNAT Gatewayを共有し、コストを最小化するか | `bool` | `true` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | VPC全体のIP範囲 (例: 10.0.0.0/16) | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | VPCの名称 (タグやリソース名の接頭辞に使用) | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_route_table_ids"></a> [app\_route\_table\_ids](#output\_app\_route\_table\_ids) | app層ルートテーブルのIDリスト |
| <a name="output_app_sg_id"></a> [app\_sg\_id](#output\_app\_sg\_id) | アプリ層用セキュリティグループのID |
| <a name="output_app_subnet_ids"></a> [app\_subnet\_ids](#output\_app\_subnet\_ids) | アプリ層（プライベート）サブネットのIDリスト |
| <a name="output_db_route_table_ids"></a> [db\_route\_table\_ids](#output\_db\_route\_table\_ids) | db層ルートテーブルのIDリスト |
| <a name="output_db_sg_id"></a> [db\_sg\_id](#output\_db\_sg\_id) | DB層用セキュリティグループのID |
| <a name="output_db_subnet_ids"></a> [db\_subnet\_ids](#output\_db\_subnet\_ids) | データ層（プライベート）サブネットのIDリスト |
| <a name="output_management_route_table_ids"></a> [management\_route\_table\_ids](#output\_management\_route\_table\_ids) | management層ルートテーブルのIDリスト（サブネットが0の場合は空リスト） |
| <a name="output_management_subnet_ids"></a> [management\_subnet\_ids](#output\_management\_subnet\_ids) | 管理層（プライベート）サブネットのIDリスト |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | パブリック用ルートテーブルのID |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | パブリックサブネットのIDリスト |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | VPCのCIDRブロック |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | VPCのID |
| <a name="output_web_sg_id"></a> [web\_sg\_id](#output\_web\_sg\_id) | Web/ALB用セキュリティグループのID |
<!-- END_TF_DOCS -->