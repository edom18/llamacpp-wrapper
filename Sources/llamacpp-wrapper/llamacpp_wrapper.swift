import llama
import Foundation

public typealias completion_callback = @convention(c) (UnsafeMutablePointer<CChar>) -> Void

public class LlamaWrapper {
    let NS_PER_S = 1_000_000_000.0
    var llamaContext: LlamaContext?
    
    var message: String = ""
    
    init() {
        
    }
    
    init(llamaContext: LlamaContext) {
        self.llamaContext = llamaContext
    }
    
    public func complete(text: String, completion: completion_callback) async -> Void {
        
        self.message = ""
        
        let t_start = DispatchTime.now().uptimeNanoseconds
        await self.llamaContext?.completion_init(text: text)
        let t_heat_end = DispatchTime.now().uptimeNanoseconds
        let t_heat = Double(t_heat_end - t_start) / NS_PER_S
        
        self.message += "\(text)"
        
        guard let llamaContext = self.llamaContext else {
            let faileMessage = strdup("Failed to create text.")
            completion(faileMessage!)
            return
        }
        
        while await llamaContext.n_cur < llamaContext.n_len {
            let result = await llamaContext.completion_loop()
            self.message += "\(result)"
            
            print(result)
        }
        
        let t_end = DispatchTime.now().uptimeNanoseconds
        let t_generation = Double(t_end - t_heat_end) / NS_PER_S
        let tokens_per_second = Double(await llamaContext.n_len) / t_generation
        
        await llamaContext.clear()
        self.message += """
        \n
        Done
        Heat up took \(t_heat)s
        Generated \(tokens_per_second) t/s\n
        """
        
        let messagePtr = strdup(self.message)
        
        completion(messagePtr!)
    }
}

@_cdecl("create_instance")
public func create_instance(_ pathPtr: UnsafePointer<CChar>) -> UnsafeMutableRawPointer {
    let path = String(cString: pathPtr)
    
    do {
        let llamaContext: LlamaContext = try LlamaContext.create_context(path: path)
        let wrapper: LlamaWrapper = LlamaWrapper(llamaContext: llamaContext)
        return Unmanaged.passRetained(wrapper).toOpaque()
    }
    catch {
        let wrapper: LlamaWrapper = LlamaWrapper()
        return Unmanaged.passRetained(wrapper).toOpaque()
    }
}

@_cdecl("llama_complete")
public func llama_complete(_ pointer: UnsafeMutableRawPointer, _ textPtr: UnsafePointer<CChar>, _ completion: completion_callback) -> Void {
    let llamaWrapper: LlamaWrapper = Unmanaged<LlamaWrapper>.fromOpaque(pointer).takeUnretainedValue()
    let text = String(cString: textPtr)
    
    Task {
        await llamaWrapper.complete(text: text, completion: completion)
    }
}
