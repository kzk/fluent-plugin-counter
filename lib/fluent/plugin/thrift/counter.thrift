namespace cpp  counter.thrift
namespace java counter.thrift
namespace perl counter.thrift

struct Event
{
  1: i64 timestamp,
  2: string category,
  3: list<string> key,
  4: i64 value
}

enum ResultCode
{
  OK,
  TRY_LATER
}

service Counter
{
  ResultCode Post(1: Event e);
}
