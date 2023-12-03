const std = @import("std");
const c = @import("c.zig");

pub const Application = struct {

  const Self = @This();

  allocator      : *const std.mem.Allocator   = undefined, //*const means pointer to constant identifier, not that the pointer itself is const, that would be const*const?

  instance       : c.VkInstance               = undefined,
  debugMessenger : c.VkDebugUtilsMessengerEXT = undefined,

  pub fn run(self: *Self, alloc : *const std.mem.Allocator) !void {
    try initVulkan(self, alloc);
    //_ = try  self.setupDebugMessenger();
    mainLoop(self);
    cleanup(self);
  }

  fn initVulkan(self: *Self, alloc : *const std.mem.Allocator) !void {
    self.allocator = alloc;

    const err = c.glfwInit();
    if(err == c.GLFW_FALSE){
      std.log.err("glfwInit failed", .{});
      return error.unkown;
    }

    const appInfo : c.VkApplicationInfo = .{
      .sType = c.VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pNext = null,
      .pApplicationName = "Hello Triangle",
      .applicationVersion = c.VK_MAKE_VERSION(1, 0, 0),
      .pEngineName = "z_coreEngine",
      .engineVersion = c.VK_MAKE_VERSION(0,1,0),
      .apiVersion = c.VK_API_VERSION_1_3
    };

    const requestedExtensions = try self.getRequestedExtensions();
    const requestedLayers     = try self.getRequestedLayers();
    defer requestedExtensions.deinit();
    defer requestedLayers    .deinit();

    std.log.info("Using the following extensions: ({d}) {s}", .{requestedExtensions.items.len, requestedExtensions.items});

    const createInfo : c.VkInstanceCreateInfo = .{
      .sType = c.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
      .pNext = null,
      .pApplicationInfo = &appInfo,
      .flags = 0,
      .enabledExtensionCount   = @intCast(u32, requestedExtensions.items.len),
      .ppEnabledExtensionNames = @ptrCast([*c]const [*c]const u8, requestedExtensions.items.ptr),
      .enabledLayerCount       = @intCast(u32, requestedLayers.items.len),
      .ppEnabledLayerNames     = @ptrCast([*c]const [*c]const u8, requestedLayers.items.ptr)
    };

    const result = c.vkCreateInstance(&createInfo, null, &self.instance);

    if(result != c.VK_SUCCESS){
      std.log.err("vkCreateInstance failed", .{});
      return error.unknown;
    }else{
      std.log.info("All ok", .{});
    }
  }

//  fn setupDebugMessenger(self: *Self) !?*anyopaque {
//
//    var myFun : ?*const fn (c.VkDebugUtilsMessageSeverityFlagBitsEXT, c.VkDebugUtilsMessageTypeFlagsEXT, [*c]const c.VkDebugUtilsMessengerCallbackDataEXT, ?*anyopaque) callconv(.C) c.VkBool32 = undefined;
//
//    myFun = struct {
//
//      fn callme (msgSeverity : c.VkDebugUtilsMessageSeverityFlagBitsEXT, msgType : c.VkDebugUtilsMessageTypeFlagsEXT, callbackData : [*c]const c.VkDebugUtilsMessengerCallbackDataEXT, userData : ?*anyopaque) callconv(.C) c.VkBool32 {
//    _ = callbackData;
//    _ = msgSeverity;
//    _ = msgType;
//    _ = userData;
//        return 0;
//      }
//    }.callme;
//
//    var myParam = struct{
//      param : c.PFN_vkDebugUtilsMessengerCallbackEXT,
//    }{
//      .param = myFun
//    };
//
//    _ = myParam;
//
//
//    const createInfo = c.VkDebugUtilsMessengerCreateInfoEXT {
//      .sType           = c.VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
//      .messageSeverity = c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
//      .messageType     = c.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | c.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
//      .pfnUserCallback = debugCallback,
//      .pUserData       = null,
//      .pNext           = null,
//      .flags           = 0
//    };
//
//    const dbgCreateFn = @as(c.PFN_vkCreateDebugUtilsMessengerEXT, c.vkGetInstanceProcAddr(self.instance, "vkCreateDebugUtilsMessengerEXT"));
//    if(dbgCreateFn == null){
//      std.log.err("vkCreateDebugUtilsMessengerEXT not found", .{});
//      return error.uknown;
//    }else{
//      return dbgCreateFn(self.instance, createInfo, null, &self.debugMessenger);
//    }
//  }

  fn getRequestedExtensions(self: *Self) !std.ArrayList(*const anyopaque){
    var glfwExtCount : u32 = undefined;
    const glfwExtPtrs = c.glfwGetRequiredInstanceExtensions(&glfwExtCount);

    //due to alignment, or whatever, strings returned from c should be treated as pointer to anyopaque
    //why isn't clear, but using []const u8 segfaults the vulkan API later on
    var extensions = std.ArrayList(*const anyopaque).init(self.allocator.*);
    std.log.info("Needs {d} exts for glfw", .{glfwExtCount});

    for(range(glfwExtCount)) |_, i|{
      try extensions.append(@ptrCast(*const anyopaque, glfwExtPtrs[i]));
    }

    try extensions.append(@ptrCast(*const anyopaque, c.VK_EXT_DEBUG_UTILS_EXTENSION_NAME));

    return extensions;
  }

  fn range(len: usize) []const void {
    //casts an undefined value to a many-items pointer, then takes a slice of that, with the specified length
    //the "values" are void, i.e. 0-bit-length and therefore should be safe against segfaulting, but the index for looping is usable

    return @as([*]void, undefined)[0..len];
  }

  fn getRequestedLayers(self: *Self) !std.ArrayList([]const u8) {
    var requestedLayers = std.ArrayList([]const u8).init(self.allocator.*);
    var presentLayers = std.ArrayList(c.VkLayerProperties).init(self.allocator.*);
    defer presentLayers.deinit();

    try requestedLayers.append("VK_LAYER_KHRONOS_validation");

    var propCount : u32 = 0;
    _ = c.vkEnumerateInstanceLayerProperties(&propCount, null); //find out how many there are
    std.log.info("Found {d} present layers", .{propCount});


    try presentLayers.ensureTotalCapacityPrecise(propCount);

    _ = c.vkEnumerateInstanceLayerProperties(&propCount, @ptrCast([*c]c.VkLayerProperties, presentLayers.items.ptr));
    presentLayers.items.len = propCount;

    if(!checkRequestedLayers(requestedLayers, presentLayers)){
      return error.unknown;
    }else {
      return requestedLayers;
    }
  }

  fn checkRequestedLayers(requestedLayers : std.ArrayList([]const u8), presentLayers : std.ArrayList(c.VkLayerProperties)) bool {
    for(requestedLayers.items) |req_layer| {
      var found = false;
      for(presentLayers.items) |pres_layer| {
        //std.log.info("Layer {s}", .{pres_layer.layerName});

        if(cmp(&pres_layer.layerName, req_layer)){
          found = true;
        }
      }
      if(!found) {
        std.log.err("Missing validation layer {s}", .{req_layer});
        return false;
      }else{
        std.log.info("{s}: Ok!", .{req_layer});
      }
    }
    return true;
  }

  ///as the pres_layer "string" has a fixed 256 length, check whether the 1st difference is the sentinel character at pos == req_layer.len
  fn cmp(lhs : []const u8, rhs : []const u8) bool {
    return std.mem.indexOfDiff(u8, lhs, rhs) == rhs.len;
  }

  //fn debugCallback (msgSeverity : c.VkDebugUtilsMessageSeverityFlagBitsEXT, msgType : c.VkDebugUtilsMessageTypeFlagsEXT, callbackData : [*c]const c.VkDebugUtilsMessengerCallbackDataEXT, userData : ?*anyopaque) callconv(.C) c.VkBool32 {
  fn debugCallback(msgSeverity : c_uint, msgType : u32, callbackData : ?*const anyopaque, userData : ?*anyopaque) callconv(.C) u32 {
    //std.log.info("{s}", .{callbackData.*.pMessage});

    _ = callbackData;
    _ = msgSeverity;
    _ = msgType;
    _ = userData;

    return 0;
  }

  fn mainLoop(self: *Self) void {
    _ = self;
  }

  fn cleanup(self: *Self) void {

    c.vkDestroyInstance(self.instance, null);
    c.glfwTerminate();
  }
};