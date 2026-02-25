variable "locationrg" {
  description = "La région Azure où les ressources seront déployées"
  type        = string
  default     = "francecentral"
}

variable "Rg_name" {
  description = "Le nom du groupe de ressources Azure"
  type        = string
  default     = "rg-SFernandesmartins2024_cours-adminazure-projet"
}
