module ScenePortabilityKit
  module ViewportResizer
    GA_ROOTOWNER = 3
    SW_RESTORE = 9

    def self.supported?
      return @supported unless @supported.nil?
      @supported = false
      if Sketchup.platform == :platform_win
        begin
          require 'fiddle/import'
          @supported = true
        rescue LoadError
        end
      end
      @supported
    end

    if supported?
      module User32
        extend Fiddle::Importer
        dlload "user32"
        typealias "BOOL", "int"
        typealias "UINT", "unsigned int"
        typealias "HWND", "unsigned int"
        typealias "LPSTR", "char*"

        extern "HWND GetAncestor(HWND, UINT)"
        extern "HWND GetActiveWindow()"
        extern "BOOL MoveWindow(HWND, UINT, UINT, UINT, UINT, BOOL)"
        extern "BOOL ShowWindow(HWND, UINT)"
        extern "BOOL GetWindowRect(HWND, LPSTR)"
      end
    end

    def self.window_handle
      return nil unless supported?
      begin
        User32.GetAncestor(User32.GetActiveWindow(), GA_ROOTOWNER)
      rescue => e
        puts "ViewportResizer: failed to get window handle: #{e.message}"
        nil
      end
    end

    def self.window_size
      return [0, 0] unless supported?
      wnd = window_handle
      return [0, 0] if wnd.nil? || wnd.zero?
      begin
        rect = [0, 0, 0, 0].pack("L*")
        User32.GetWindowRect(wnd, rect)
        left, top, right, bottom = rect.unpack("L*").map { |e| [e].pack("L").unpack("l").first }
        [right - left, bottom - top]
      rescue => e
        puts "ViewportResizer: failed to get window size: #{e.message}"
        [0, 0]
      end
    end

    def self.resize_window(width, height)
      return unless supported?
      wnd = window_handle
      return if wnd.nil? || wnd.zero?
      begin
        User32.ShowWindow(wnd, SW_RESTORE)
        rect = [0, 0, 0, 0].pack("L*")
        User32.GetWindowRect(wnd, rect)
        left, top, _right, _bottom = rect.unpack("L*").map { |e| [e].pack("L").unpack("l").first }
        User32.MoveWindow(wnd, left, top, width, height, 1)
      rescue => e
        puts "ViewportResizer: failed to resize window: #{e.message}"
      end
    end

    def self.resize_viewport(width, height)
      return unless supported?
      view = Sketchup.active_model.active_view
      begin
        vp_w = view.vpwidth
        vp_h = view.vpheight
        return if vp_w == width && vp_h == height

        w_w, w_h = window_size
        return if w_w.zero? || w_h.zero?

        chrome_w = w_w - vp_w
        chrome_h = w_h - vp_h

        new_w = width + chrome_w
        new_h = height + chrome_h

        resize_window(new_w, new_h)
      rescue => e
        puts "ViewportResizer: resize_viewport failed: #{e.message}"
      end
    end
  end
end
