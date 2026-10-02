# frozen_string_literal: true

class SolidServerIPAddr < IPAddr
  # converts to nework address (discarding other bits)
  def net_addr!
    @addr &= @mask_addr
    self
  end

  def net_addr
    clone.net_addr!
  end

  def last_addr!
    case @family
    when Socket::AF_INET
      @addr |= (IPAddr::IN4MASK ^ @mask_addr)
    when Socket::AF_INET6
      @addr |= (IPAddr::IN6MASK ^ @mask_addr)
    end
    self
  end

  def last_addr
    clone.last_addr!
  end

  def broadcast_addr!
    raise AddressFamilyError, 'unsupported address family' unless @family == Socket::AF_INET

    last_addr!
  end

  def broadcast_addr
    clone.broadcast_addr!
  end
end
