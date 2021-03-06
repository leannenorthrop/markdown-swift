//
//  HtmlRenderer.swift
//  Markdown
//
//  Created by Leanne Northrop on 22/06/2015.
//  Copyright (c) 2015 Leanne Northrop. All rights reserved.
//

import Foundation
public class HtmlRenderer: Renderer {
    public override init() { super.init() }

    public func toHTML(source : [AnyObject]) -> String {
        var src : [AnyObject]? = source
        var input = self.toHTMLTree(&src, preprocessTreeNode: nil)
        return self.renderHTML(input, includeRoot: true)
    }
    
    public func toHTMLTree(input: String, dialectName : String, options : AnyObject) -> [AnyObject] {
        let md = Markdown(dialectName: dialectName)
        var result : [AnyObject]? = md.parse(input)
        return self.toHTMLTree(&result, preprocessTreeNode: nil)
    }
    
    public func toHTMLTree(inout input : [AnyObject]?,
                           preprocessTreeNode : (([AnyObject],[String:Ref]) -> [AnyObject])!) -> [AnyObject] {
        // Convert the MD tree to an HTML tree
        
        // remove references from the tree
        var refs : [String:Ref]
        var i = input!
        refs = i[1] as! [String:Ref]
        var html = convert_tree_to_html(&input, refs: refs, preprocessTreeNode: preprocessTreeNode)
        //todomerge_text_nodes(html)
        
        return html
    }
    
    func extract_attr(jsonml : [AnyObject]) -> [String:AnyObject]? {
        if jsonml.count > 1 {
            if let attrs = jsonml[1] as? [String:AnyObject] {
                return jsonml[1] as? [String:AnyObject]
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func convert_tree_to_html(inout tree : [AnyObject]?,
                              refs : [String:Ref],
                              preprocessTreeNode : (([AnyObject],[String:Ref]) -> [AnyObject])!) -> [AnyObject] {
        if tree == nil {
            return []
        }
                                
        // shallow clone
        var jsonml : [AnyObject] = []
        if preprocessTreeNode != nil {
            jsonml = preprocessTreeNode(tree!, refs)
        } else {
            jsonml = tree!
        }

        var attrs : [String:AnyObject]? = extract_attr(jsonml)
    
        // convert this node
        if !(jsonml[0] is String) {
            if jsonml[0] is [AnyObject] {
                var subtree : [AnyObject]? = jsonml[0] as? [AnyObject]
                return convert_tree_to_html(&subtree, refs: refs, preprocessTreeNode: preprocessTreeNode)
            } else {
                return []
            }
        }
        var nodeName : String = jsonml[0] as! String
        switch nodeName {
            case "header":
                jsonml[0] = "h" + ((attrs?["level"])! as! String)
                attrs?.removeValueForKey("level")
            case "bulletlist":
                jsonml[0] = "ul"
            case "numberlist":
                jsonml[0] = "ol"
            case "listitem":
                jsonml[0] = "li"
            case "para":
                jsonml[0] = "p"
            case "markdown":
                jsonml[0] = "body"
                if attrs != nil {
                    attrs?.removeValueForKey("refs")
                }
            case "code_block":
                jsonml[0] = "pre"
                var j = attrs != nil ? 2 : 1
                var code : [AnyObject] = ["code"]
                code.extend(jsonml[j...jsonml.count-j])
                jsonml[j] = code
            case "uchen_block":
                jsonml[0] = "p"
                var j = attrs != nil ? 2 : 1
                var uchen : [AnyObject] = ["uchen"]
                uchen.extend(jsonml[j...jsonml.count-j])
                jsonml[j] = uchen
            case "uchen":
                jsonml[0] = "span"
            case "inlinecode":
                jsonml[0] = "code"
            case "img":
                println("img")
                //todo jsonml[1].src = jsonml[ 1 ].href;
                //delete jsonml[ 1 ].href;
            case "linebreak":
                jsonml[0] = "br"
            case "link":
                jsonml[0] = "a"
            case "link_ref":
                jsonml[0] = "a"
                if attrs != nil {
                    var attributes : [String:AnyObject] = attrs!
                    var key = attributes["ref"] as? String
                    if key != nil {
                        // grab this ref and clean up the attribute node
                        var ref = refs[key!]
            
                        // if the reference exists, make the link
                        if ref != nil {
                            attrs!.removeValueForKey("ref")
                            // add in the href if present
                            attrs!["href"] = ref!.href
                            
                            // get rid of the unneeded original text
                            attrs!.removeValueForKey("original")
                            
                            jsonml[1] = attrs!
                        } else {
                            return (attributes.indexForKey("original") != nil) ? [attributes["original"]!] : []
                        }
                    }
                }
            case "img_ref":
                jsonml[0] = "img"
                if attrs != nil {
                    var attributes : [String:AnyObject] = attrs!
                    var key = attributes["ref"] as? String
                    if key != nil {
                        // grab this ref and clean up the attribute node
                        var ref = refs[key!]
                        
                        // if the reference exists, make the link
                        if ref != nil {
                            attrs!.removeValueForKey("ref")
                            // add in the href if present
                            attrs!["href"] = ref!.href
                            
                            // get rid of the unneeded original text
                            attrs!.removeValueForKey("original")
                            
                            jsonml[1] = attrs!
                        } else {
                            return (attributes.indexForKey("original") != nil) ? [attributes["original"]!] : []
                        }
                    }
                }
            default:
                println("convert_to_html encountered unsupported element " + nodeName)
        }
    
        // convert all the children
        var l = 1
    
        // deal with the attribute node, if it exists
        if attrs != nil {
            var attributes = attrs!
            // if there are keys, skip over it
            for (key,value) in attributes {
                l = 2
                break
            }
        }
                                
        // if there aren't, remove it
        //if l == 1 {
        //    jsonml.removeAtIndex(1)
        //}
    
        for l; l < jsonml.count; ++l {
            if (jsonml[l] is [AnyObject]) {
                var node : [AnyObject]? = jsonml[l] as! [AnyObject]
                jsonml[l] = convert_tree_to_html(&node, refs: refs, preprocessTreeNode: preprocessTreeNode)
            }
        }
    
        return jsonml
    }
    
    func renderHTML(var jsonml : [AnyObject], includeRoot : Bool) -> String {
        var content : [String] = []
        
        if includeRoot {
            content.append("<!DOCTYPE html>")
            content.append("<html>")
            content.append("<head>")
            content.append("<meta charset=\"UTF-8\">")
            content.append("<title>Markdown</title>")
            content.append("</head>")
            content.append(super.render_tree(jsonml))
            content.append("</html>")
        } else {
            // remove tag
            jsonml.removeAtIndex(0)
            if var objArray = jsonml[0] as? [AnyObject] {
                // remove attributes
                objArray.removeAtIndex(0)
            }
            
            while jsonml.count > 0 {
                var v : AnyObject? = jsonml.removeAtIndex(0)
                if v is String {
                    content.append(super.render_tree(v as! String))
                } else if v is [AnyObject] {
                    let arr : [AnyObject] = v as! [AnyObject]
                    content.append(super.render_tree(arr))
                } else  {
                    println("HTML renderer found a " + v!.type)
                }
            }
        }
        
        var joiner = "\n\n"
        var joined = joiner.join(content)
        return joined
    }
}