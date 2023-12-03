const std = @import("std");
const c = @import("c.zig");

const app = @import("app.zig");

pub fn main() !void {

  try random_tests();

  var application = app.Application {};
  try application.run(&std.heap.page_allocator);
}

fn random_tests() !void {
  // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
  // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

  // stdout is for the actual output of your application, for example if you
  // are implementing gzip, then only the compressed bytes should be sent to
  // stdout, not any debugging messages.

  var args_it = try std.process.argsWithAllocator(std.heap.page_allocator);
  defer args_it.deinit();

  _ = args_it.skip(); //skip process name
  const debugger = args_it.next();


  std.log.info("Hello {?s}-{s}", .{debugger, "World"});

  var list = std.ArrayList(i32).init(std.heap.page_allocator);
  defer list.deinit();
  try list.append(32);

  std.log.info("Listie[0]: {d}", .{list.items[0]});

  const asd = test_fn();

  std.log.info("u17.MAX_VALUE: {!d}", .{asd});
}

fn test_fn() !u17 {
  const constantVal = 255;
  var variable:i32 = -5000;

  var dontknow:u17 = undefined;

  const inferedConst = @as(u8, constantVal);
  _=inferedConst;
  _=variable;

  const array_a = [8]u8{0,0,0,5,2,1,0,0};

  std.log.info("yee {!d}", .{array_a});

  dontknow = @intCast(u17, std.math.pow(u18, 2, 17)-1);

  return dontknow;
}