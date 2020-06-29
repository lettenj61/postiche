export interface Member {
  name: string
  comment: string
}

export type Union = Member & {
  args: string[]
  cases: [string, string[]]
}

export type Value = Member & {
  type: string
}

export type Module = Member & {
  unions: Union[]
  aliases: any[]
  values: Value[]
}