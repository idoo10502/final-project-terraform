# ⁧קורא את שם האזור מה-provider ולכן לא צריך להעביר אותו כקלט⁩
data "aws_region" "current" {}

locals {
  # ⁧שם הקונטיינר, משותף ל-task ול-load_balancer כדי שלא יתפצלו⁩
  container_name = "app"

  # ⁧בונים את הגדרת הקונטיינר כמפה אחת, והפונקציה merge מחברת כמה מפות לאחת⁩
  container = merge(
    {
      # ⁧שם הקונטיינר⁩
      name = local.container_name
      # ⁧ה-image המלא כולל התג⁩
      image = var.image
      # ⁧אם הקונטיינר נופל, כל ה-task נופל איתו⁩
      essential = true
      # ⁧הופך מפה פשוטה לרשימה של זוגות שם וערך, כפי ש-ECS דורש⁩
      environment = [for k, v in var.environment : { name = k, value = v }]
      logConfiguration = {
        # ⁧שולח את הלוגים אל CloudWatch כדי שאפשר יהיה לראות אותם⁩
        logDriver = "awslogs"
        options = {
          # ⁧לאיזו קבוצת לוגים לכתוב⁩
          awslogs-group = aws_cloudwatch_log_group.this.name
          # ⁧באיזה אזור נמצאת הקבוצה⁩
          awslogs-region = data.aws_region.current.name
          # ⁧קידומת לשם הזרם בתוך הקבוצה⁩
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    # ⁧אם אין פורט, כמו ב-worker, לא מוסיפים את מפתח הפורטים בכלל⁩
    var.container_port == null ? {} : {
      portMappings = [{ containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }]
    },
    # ⁧אם אין סודות לא מוסיפים את המפתח הזה, ובזמן עלייה קורא ECS כל סוד בעצמו⁩
    length(var.secrets) == 0 ? {} : {
      secrets = [for k, v in var.secrets : { name = k, valueFrom = v }]
    },
  )
}

resource "aws_cloudwatch_log_group" "this" {
  # ⁧שם הקבוצה נגזר משם השירות⁩
  name = "/ecs/${var.name}"
  # ⁧הלוגים נמחקים אחרי שבוע כדי לחסוך בעלות⁩
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "this" {
  # ⁧שם התבנית, וכל שינוי בה יוצר גרסה חדשה⁩
  family = var.name
  # ⁧הרצה על Fargate בלי שרתים לנהל⁩
  requires_compatibilities = ["FARGATE"]
  # ⁧זה חובה כשמריצים עם Fargate, ולכל משימה יש כרטיס רשת משלה⁩
  network_mode = "awsvpc"
  # ⁧רבע ליבה, כמחרוזת כי כך ECS דורש⁩
  cpu = "256"
  # ⁧חצי ג'יגה של זיכרון⁩
  memory = "512"
  # ⁧ה-role שבו ECS משתמש כדי למשוך image ולקרוא סודות⁩
  execution_role_arn = var.execution_role_arn

  # ⁧ECS מצפה לרשימת קונטיינרים בפורמט JSON, וכאן יש קונטיינר אחד⁩
  container_definitions = jsonencode([local.container])
}

resource "aws_ecs_service" "this" {
  # ⁧שם השירות⁩
  name = var.name
  # ⁧באיזה cluster השירות רץ⁩
  cluster = var.cluster_id
  # ⁧איזו תבנית להריץ⁩
  task_definition = aws_ecs_task_definition.this.arn
  # ⁧כמה עותקים אמורים לרוץ בכל רגע⁩
  desired_count = var.desired_count
  # ⁧שוב הרצה על Fargate בלי שרתים⁩
  launch_type = "FARGATE"

  # ⁧הפקודה apply לא נגמרת עד שהפריסה מסתיימת, בהצלחה או בחזרה אחורה⁩
  wait_for_steady_state = true

  deployment_circuit_breaker {
    # ⁧ECS מזהה פריסה שנכשלת שוב ושוב ועוצר אותה⁩
    enable = true
    # ⁧ואז חוזר לבד לגרסה האחרונה שעבדה⁩
    rollback = true
  }

  # ⁧חזרה אחורה אחרי קריסה יכולה לקחת 10 עד 20 דקות, אז נותנים יותר זמן⁩
  timeouts {
    create = "30m"
    update = "30m"
  }

  network_configuration {
    # ⁧באילו subnets ירוצו ה-tasks⁩
    subnets = var.subnet_ids
    # ⁧אילו חוקי רשת חלים עליהם, כלומר ecs-sg⁩
    security_groups = var.security_group_ids
    # ⁧כתובת ציבורית כדי למשוך image, כי אין NAT בפרויקט⁩
    assign_public_ip = true
  }

  # ⁧הבלוק הזה מופיע רק כשיש target group, ובשירות worker הוא לא יופיע בכלל⁩
  dynamic "load_balancer" {
    # ⁧רשימה ריקה נותנת אפס בלוקים, ורשימה עם איבר אחד נותנת בלוק אחד⁩
    for_each = var.target_group_arn == null ? [] : [var.target_group_arn]

    content {
      # ⁧הכתובת של ה-target group⁩
      target_group_arn = load_balancer.value
      # ⁧לאיזה קונטיינר להעביר את התעבורה⁩
      container_name = local.container_name
      # ⁧ובאיזה פורט⁩
      container_port = var.container_port
    }
  }
}