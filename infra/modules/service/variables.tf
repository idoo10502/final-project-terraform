# השם המלא של השירות
variable "name" {
  description = "Full name of the service, e.g. ido-dev-vote"
  type        = string
}

# ה-image המלא כולל התג, ומשתנה בין שירות לשירות
variable "image" {
  description = "Full image URI with tag"
  type        = string
}

# המזהה של ה-cluster שבו השירות ירוץ
variable "cluster_id" {
  type = string
}

# הכתובת של ה-role שמאפשר ל-ECS למשוך image ולקרוא סודות
variable "execution_role_arn" {
  type = string
}

# רשימת ה-subnets שבהם ה-tasks ירוצו
variable "subnet_ids" {
  type = list(string)
}

# רשימת ה-security groups שיחולו על ה-tasks
variable "security_group_ids" {
  type = list(string)
}

# כמה עותקים ירוצו, ואם לא מציינים יש עותק אחד
variable "desired_count" {
  type    = number
  default = 1
}

# משתני סביבה רגילים, בצורת שם וערך
variable "environment" {
  description = "Plain environment variables (name => value)"
  type        = map(string)
  default     = {}
}

# סודות, בצורת שם וכתובת של הסוד ב-Secrets Manager
variable "secrets" {
  description = "Secrets (name => Secrets Manager ARN)"
  type        = map(string)
  default     = {}
}

# הפורט של הקונטיינר, וערך null אומר שאין פורט כמו ב-worker
variable "container_port" {
  description = "Port of the container. null = no port (worker)"
  type        = number
  default     = null
}

# ה-target group שאליו השירות נרשם, וערך null אומר שהוא לא מאחורי ה-ALB
variable "target_group_arn" {
  description = "Target group to register in. null = not behind the ALB"
  type        = string
  default     = null
}