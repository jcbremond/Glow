//
//  ViewController.swift
//  Glow
//
//  Created by Justin Bush on 2017-11-20.
//  Copyright © 2017 Justin Bush. All rights reserved.
//

import Cocoa
import WebKit

class ViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, NSTextFieldDelegate, NSTextDelegate {
    
    // Main View Elements
    @IBOutlet var webView: WKWebView!
    @IBOutlet var addressBar: NSTextField!
    @IBOutlet var moveFullScreen: NSTextFieldCell!
    @IBOutlet var progressBar: NSProgressIndicator!
    @IBOutlet var navConstraint: NSLayoutConstraint!
    @IBOutlet var sideConstraint: NSLayoutConstraint!
    
    // Side Menu Buttons
    @IBOutlet var refreshButton: NSButton!
    @IBOutlet var bookmarkButton: NSButton!
    @IBOutlet var homeButton: NSButton!
    
    var searchRequest = ""
    
    override func viewWillAppear() {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.activeAddressBarNotification(_:)), name: NSNotification.Name(rawValue: "ActiveAddressBar"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.toggleSideMenuNotification(_:)), name: NSNotification.Name(rawValue: "ToggleSideMenu"), object: nil)
        
        
        let gradient = CAGradientLayer()
        
        gradient.colors = [NSColor.blue.cgColor,
                           NSColor.red.cgColor,
                           NSColor.green.cgColor]
        
        gradient.locations = [0, 0.5, 1.0]
        
        gradient.frame = view.frame

        //view.layer.mask = gradient
        progressBar.layer?.mask = gradient
        //progressBar.controlTint = gradient
        //progressBar.layer?.borderColor = CGColor.clear
        //progressBar.layer?.backgroundColor = CGColor.clear
        //progressBar.layer?.compositingFilter = gradient
        progressBar.wantsLayer = true
        //progressBar.isBezeled = false
        addressBar.resignFirstResponder()
        
    }
    
    override func viewWillDisappear() {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    // Observer for WebView Loading Progress
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "estimatedProgress") {
            DispatchQueue.main.async {
                self.setProgress(self.webView.estimatedProgress * 100)
            }
        }
    }
    
    // Set Progress for ProgressBar
    fileprivate func setProgress(_ value: Double) {
        if value == 100 {
            self.progressBar.isHidden = true
            return
        }
        
        self.progressBar.isHidden = false
        self.progressBar.doubleValue = value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.isHidden = true
        
        // WebView Configuration
        webView.navigationDelegate = self
        webView.allowsLinkPreview = true
        webView.allowsMagnification = true
        webView.allowsBackForwardNavigationGestures = true
        webView.configuration.allowsAirPlayForMediaPlayback = true
        webView.configuration.preferences.javaScriptEnabled = true
        
        // WebView UserAgent (Safari)
        webView.configuration.applicationNameForUserAgent = "Glow"
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_1) AppleWebKit/604.3.5 (KHTML, like Gecko) Version/11.0.1 Safari/604.3.5"
        
        // AddressBar Configuration
        addressBar.delegate = self
        
        // WebView Debug
        let request = URL(string: "https://medium.com")!
        webView.load(URLRequest(url: request))
        webView.setValue(false, forKey: "drawsBackground")
        webView.enclosingScrollView?.backgroundColor = NSColor.clear
        
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        webView.isHidden = false
        progressBar.isHidden = false
        //updateAddressBar(input: "")
        deselectAdressBar()
        addressBar.refusesFirstResponder = true
        //webView.becomeFirstResponder()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressBar.isHidden = true
        self.setProgress(100)
        
        let niceURL = prettyURL(input: webView.url! as NSURL)
        updateAddressBar(input: niceURL)
        deselectAdressBar()
        
        webView.becomeFirstResponder()
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.setProgress(0)
        //addressBar.refusesFirstResponder = true
        addressBar.resignFirstResponder()
    }
    
    // AddressBar: Load Request
    func loadRequest(input: String) {
        
        // Check for Valid URL Request
        if isURL(input: input) {
            let request = URL(string: input)!
            webView.load(URLRequest(url: request))
            
        } else {
            // Check for URL without HTTP Prefix
            let preRegEx = "((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
            
            if NSPredicate(format: "SELF MATCHES %@", preRegEx).evaluate(with: input) {
                let updatedRequest = URL(string: "http://" + input)!
                webView.load(URLRequest(url: updatedRequest))
                
            } else {
                // Request is a Search Query
                searchRequest = input
                let searchQuery = "https://google.com/search?q=" + input
                let updatedRequest = URL(string: searchQuery.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil))
                webView.load(URLRequest(url: updatedRequest!))
            }
        }
    }
    
    @IBAction func refreshPage(_: Any?) {
        webView.reload()
    }
    
    @IBAction func showSideMenu(_: Any?) {
        addressBar.isHidden = false
        navConstraint.constant = 40.0
        sideConstraint.constant = 40.0
    }
    
    @IBAction func hideSideMenu(_: Any?) {
        addressBar.isHidden = true
        navConstraint.constant = 0.0
        sideConstraint.constant = 0.0
    }
    
    // AddressBar: Update URL
    func updateAddressBar(input: String) {
        if (input.isEmpty) {
            let updatedURL = (webView.url?.absoluteString)!
            addressBar.stringValue = updatedURL
        } else {
            addressBar.stringValue = input
        }
    }
    
    // AddressBar: Pretty URL
    func prettyURL(input: NSURL) -> String {
        var prettyURL = input.host
        
        if prettyURL?.lowercased().range(of:"google.") != nil {
            prettyURL = searchRequest
        } else if prettyURL?.lowercased().range(of:"www.") != nil {
            prettyURL = prettyURL?.replacingOccurrences(of: "www.", with: "", options: .literal, range: nil)
        }
        
        return prettyURL!
    }
    
    // Valid URL Check
    func isURL(input: String?) -> Bool {
        let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: input)
    }
    
    @objc func activeAddressBarNotification(_ aNotification: Notification) {
        addressBar.stringValue = (webView.url?.absoluteString)!
    }
    
    @objc func toggleSideMenuNotification(_ aNotification: Notification) {
        let customTimeFunction = CAMediaTimingFunction(controlPoints: 5/6, 0.2, 2/6, 0.9)
        if addressBar.isHidden {
            /*
                addressBar.isHidden = false
                navConstraint.constant = 40.0
                sideConstraint.constant = 40.0
 */
            
            NSAnimationContext.runAnimationGroup({(_ context: NSAnimationContext) -> Void in
                //context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                context.timingFunction = customTimeFunction
                context.duration = 0.3
                navConstraint.animator().constant = 40.0
                sideConstraint.animator().constant = 40.0
                addressBar.animator().isHidden = false
            }, completionHandler: {() -> Void in
            })
            
        } else {
            NSAnimationContext.runAnimationGroup({(_ context: NSAnimationContext) -> Void in
                //context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
                context.timingFunction = customTimeFunction
                context.duration = 0.3
                navConstraint.animator().constant = 0.0
                sideConstraint.animator().constant = 0.0
                addressBar.animator().isHidden = true
            }, completionHandler: {() -> Void in
            })
        }
    }
    
    // AddressBar: User Began Editing AddressBar
    override func controlTextDidBeginEditing(_ aNotification: Notification) {
        //addressBar.stringValue = (webView.url?.absoluteString)!
    }
    
    // AddressBar: User Finished Editing AddressBar
    override func controlTextDidEndEditing(_ aNotification: Notification) {
        if !addressBar.stringValue.isEmptyOrSpaces() {
            loadRequest(input: addressBar.stringValue)
            deselectAdressBar()
        }
    }
    
    func deselectAdressBar() {
        if let selectedRange = addressBar.currentEditor()?.selectedRange {
            DispatchQueue.main.async {
                self.addressBar.currentEditor()?.selectedRange = selectedRange
            }
        }
    }
    
    // Window Action: FullScreen
    public func updateForFullScreenMode() {
        let customTimeFunction = CAMediaTimingFunction(controlPoints: 5/6, 0.2, 2/6, 0.9)
        NSAnimationContext.runAnimationGroup({(_ context: NSAnimationContext) -> Void in
            //context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            context.timingFunction = customTimeFunction
            context.duration = 0.3
            navConstraint.animator().constant = 0.0
            sideConstraint.animator().constant = 0.0
            addressBar.animator().isHidden = true
        }, completionHandler: {() -> Void in
        })
    }
    
    // Window Action: Window
    public func updateForWindowMode() {
        let customTimeFunction = CAMediaTimingFunction(controlPoints: 5/6, 0.2, 2/6, 0.9)
        NSAnimationContext.runAnimationGroup({(_ context: NSAnimationContext) -> Void in
            //context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            context.timingFunction = customTimeFunction
            context.duration = 0.3
            navConstraint.animator().constant = 40.0
            sideConstraint.animator().constant = 40.0
            addressBar.animator().isHidden = false
        }, completionHandler: {() -> Void in
        })
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

}

extension String {
    
    func isEmptyOrSpaces() -> Bool {
        
        if (self.isEmpty) {
            return true
        }
        return (self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) == "test")
    }
}

extension NSTextField {
    
    open override func becomeFirstResponder() -> Bool {
        NotificationCenter.default.post(name: Notification.Name("ActiveAddressBar"), object: nil)
        return true
    }
    
}

