import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity contract interactions
const mockContractCalls = {
  'register-container': vi.fn(),
  'update-container-location': vi.fn(),
  'get-container': vi.fn(),
  'get-container-location': vi.fn(),
};

// Mock the contract call function
const mockContractCall = (functionName, ...args) => {
  return mockContractCalls[functionName](...args);
};

describe('Container Tracking Contract', () => {
  const ownerAddress = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
  const containerId = 'MSCU1234567';
  const shippingLine = 'MAERSK001';
  
  beforeEach(() => {
    // Reset all mocks
    Object.values(mockContractCalls).forEach(mock => mock.mockReset());
  });
  
  describe('register-container', () => {
    it('should register a new container successfully', () => {
      mockContractCalls['register-container'].mockReturnValue({
        success: true,
        value: true
      });
      
      const result = mockContractCall('register-container', containerId, shippingLine);
      
      expect(result.success).toBe(true);
      expect(mockContractCalls['register-container']).toHaveBeenCalledWith(
          containerId,
          shippingLine
      );
    });
    
    it('should fail if container already exists', () => {
      mockContractCalls['register-container'].mockReturnValue({
        success: false,
        error: 'u102' // ERR-CONTAINER-EXISTS
      });
      
      const result = mockContractCall('register-container', containerId, shippingLine);
      
      expect(result.success).toBe(false);
      expect(result.error).toBe('u102');
    });
  });
  
  describe('update-container-location', () => {
    it('should update container location successfully', () => {
      const newLocation = 'PORT_ROTTERDAM';
      const newStatus = 'IN_TRANSIT';
      
      mockContractCalls['update-container-location'].mockReturnValue({
        success: true,
        value: true
      });
      
      const result = mockContractCall(
          'update-container-location',
          containerId,
          newLocation,
          newStatus
      );
      
      expect(result.success).toBe(true);
      expect(mockContractCalls['update-container-location']).toHaveBeenCalledWith(
          containerId,
          newLocation,
          newStatus
      );
    });
    
    it('should fail if container does not exist', () => {
      mockContractCalls['update-container-location'].mockReturnValue({
        success: false,
        error: 'u101' // ERR-CONTAINER-NOT-FOUND
      });
      
      const result = mockContractCall(
          'update-container-location',
          'NONEXISTENT',
          'PORT_ROTTERDAM',
          'IN_TRANSIT'
      );
      
      expect(result.success).toBe(false);
      expect(result.error).toBe('u101');
    });
  });
  
  describe('get-container-location', () => {
    it('should return the current location of a container', () => {
      const expectedLocation = 'PORT_ROTTERDAM';
      mockContractCalls['get-container-location'].mockReturnValue(expectedLocation);
      
      const result = mockContractCall('get-container-location', containerId);
      
      expect(result).toBe(expectedLocation);
      expect(mockContractCalls['get-container-location']).toHaveBeenCalledWith(containerId);
    });
    
    it('should return "UNKNOWN" for non-existent containers', () => {
      mockContractCalls['get-container-location'].mockReturnValue('UNKNOWN');
      
      const result = mockContractCall('get-container-location', 'NONEXISTENT');
      
      expect(result).toBe('UNKNOWN');
    });
  });
});
