/**
    XServer iOS SDK

    © XScoder 2021
    All Rights reserved

    * IMPORTANT *
    RE-SELLING THIS SOURCE CODE TO ANY ONLINE MARKETPLACE
    IS A SERIOUS COPYRIGHT INFRINGEMENT, AND YOU WILL BE
    LEGALLY PROSECUTED
**/

import Foundation
import UIKit
import CoreLocation


// PLACE YOUR APP NAME HERE:
let APP_NAME = "YOUR_APP_NAME"


// MARK: - PASTE YOUR DATABASE PATH HERE:
let DATABASE_PATH = "YOUR_DATABASE_PATH"




// ------------------------------------------------
// MARK: - GLOBAL VARIABLES - DO NOT EDIT THESE VARIABLES
// ------------------------------------------------
var DEFAULTS = UserDefaults.standard
var IOS_DEVICE_TOKEN = ""
var ANDROID_DEVICE_TOKEN = ""
let TABLES_PATH = DATABASE_PATH + "_Tables/"


// ------------------------------------------------
// MARK: - XServer -> COMMON ERROR MESSAGES
// ------------------------------------------------
let XS_ERROR = "No response from server. Try again later."
let E_101 = "Username already exists. Please choose another one."
let E_102 = "Email already exists. Please choose another one."
let E_103 = "Object not found."
let E_104 = "Something went wrong while sending a Push Notification."
let E_301 = "Email doesn't exists in the database. Try a new one."
let E_302 = "You have signed in with a Social account, password cannot be changed."
let E_201 = "Something went wrong while creating/updating data."
let E_202 = "Either the username or password are wrong. Please type them again."
let E_203 = "Something went wrong while deleting data."
let E_401 = "File upload failed. Try again"


//------------------------------------------------------------------------
//------------------------------------------------------------------------
// MARK: - XServer FUNCTIONS
//------------------------------------------------------------------------
//------------------------------------------------------------------------
extension UIViewController {
    
    // ------------------------------------------------
    // MARK: - XSCurrentUser -> GET CURRENT USER DATA
    // ------------------------------------------------
    func XSCurrentUser(completion: @escaping (_ currUser:JSON?) -> Void) {
        let currentUser = DEFAULTS.object(forKey: "currentUser")
        print("currentUser DEFAULTS: \(String(describing: currentUser))")
             
        if currentUser != nil {
            let parameters = "tableName=Users"
            let session = URLSession(configuration: .ephemeral)
            let myUrl = URL(string: TABLES_PATH + "m-query.php?");
            var request = URLRequest(url:myUrl!)
            request.httpMethod = "POST"
            request.httpBody = parameters.data(using: .utf8)
            let task = session.dataTask(with: request) { (data, response, error)  in
                if error != nil {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }
                     
                DispatchQueue.main.async {
                    let users = try! JSON(data: data!)
                    var ok = false
                       
                    // Search for currentUser obj
                    if users.count != 0 {
                        for i in 0..<users.count {
                            let uObj = users[i]
                            if uObj["ID_id"].string == "\(currentUser!)" {
                                print("* CURRENT USER: \(String(describing: uObj["ST_username"].string!)) *\n")
                                ok = true
                                completion(uObj)
                            }
                               
                            // User doesn't exists in database
                            if (i == users.count-1 && !ok) {
                                DEFAULTS.set(nil, forKey: "currentUser")
                                completion(nil)
                            }
                        }// ./ For
                       
                    // NO currentUser
                    } else { completion(nil) }
                       
                }// ./ Dispatch
            }; task.resume()
                 
        // currentUser is nil
        } else { DispatchQueue.main.async { completion(nil) } }
    }
    
      
      
      
     // ------------------------------------------------
    // MARK: - XSSignIn -> SIGN IN
    // ------------------------------------------------
    func XSSignIn(username:String, password:String, completion: @escaping (_ success:Bool?, _ error:String?) -> Void)  {
        let parameters = "tableName=Users"
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "m-query.php?");
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        let task = session.dataTask(with: request) { (data, response, error)  in
            if error != nil {
                DispatchQueue.main.async { completion(false, error!.localizedDescription) }
                return
            }
            
            DispatchQueue.main.async {
                // Get data
                let objects = try! JSON(data: data!)
                var ok = false
                
                // Search for currentUser obj
                if objects.count != 0 {
                    for i in 0..<objects.count {
                        let uObj = objects[i]
                        if uObj["ST_username"].string == username && uObj["ST_password"].string == password {
                            print("** SIGNED IN AS: \(String(describing: uObj["ST_username"].string!)) **\n-------------------")
                            DEFAULTS.set(uObj["ID_id"].string!, forKey: "currentUser")
                            ok = true
                            completion(true, nil)
                        }
                        
                        // User doesn't exists in database or credentials are wrong
                        if i == objects.count-1 && !ok { completion(false, E_202) }
                    }// ./ For
                   
                // No users in the database!
                } else { completion(false, E_202) }
            }// ./ Dispatch
            
        }; task.resume()
    }
      
    
    
    // ------------------------------------------------
    // MARK: - XSSignUp -> SIGN UP
    // ------------------------------------------------
    func XSSignUp(username:String, password:String, email:String, signInWith:String, completion: @escaping (_ results:String?, _ error:String?) -> Void) {
        let parameters = ["ST_username": username, "ST_password": password, "ST_email": email, "signInWith": signInWith, "ST_iosDeviceToken": IOS_DEVICE_TOKEN, "ST_androidDeviceToken": ANDROID_DEVICE_TOKEN]
        
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "m-signup.php?")
        var request = URLRequest(url:myUrl!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = parameters.percentEncoded()
        let task = session.dataTask(with: request) { data, response, error in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async {
                    completion(nil, error!.localizedDescription)
                }
                return
            }
            
            if let response = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                print("XSSignUp -> RESPONSE: " + response + "\n-------------------")
                      
                DispatchQueue.main.async {
                    if response == "e_101" { completion(nil, E_101)
                    } else if response == "e_102" { completion(nil, E_102)
                    // Sing Up
                    } else {
                        completion(response, nil)
                        let resultsArr = response.components(separatedBy: "-")
                        let uID = resultsArr[0]
                        DEFAULTS.set(uID, forKey: "currentUser")
                    }// ./ IF
                }// ./Dispatch
                
            // No response
            } else { DispatchQueue.main.async { completion(nil, XS_ERROR) } }// ./ If response
        }; task.resume()
    }
    
    
    
    
    // ------------------------------------------------
    // MARK: - XSResetPassword -> RESET PASSWORD
    // ------------------------------------------------
    func XSResetPassword(email:String, completion: @escaping (_ result:String?, _ error:String?) -> Void) {
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "forgot-password.php?email=\(email)")
        let request = URLRequest(url:myUrl!)
        let task = session.dataTask(with: request) { data, response, error in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(nil, error!.localizedDescription) }
                return
            }
            if let response = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                print("XSResetPassword -> RESPONSE: " + response)
                
                DispatchQueue.main.async {
                    if response == "e_301" { completion(nil, E_301)
                    } else if response == "e_302" { completion(nil, E_302)
                    } else { completion(response, nil) }
                }
                
            // No response
            } else { DispatchQueue.main.async { completion(nil, XS_ERROR) } }// ./ If response
        }; task.resume()
    }
    

    // ------------------------------------------------
    // MARK: - XSLogout -> LOGOUT
    // ------------------------------------------------
    func XSLogout(completion: @escaping (_ success:Bool?) -> Void) {
        DispatchQueue.main.async {
          DEFAULTS.set(nil, forKey: "currentUser")
          completion(true)
        }
    }

   
    
    // ------------------------------------------------
    // MARK: - XSGetPointer -> GET POINTER OBJECT
    // ------------------------------------------------
    func XSGetPointer(_ id:String, tableName:String, completion: @escaping (_ userPointer:JSON?) -> Void) {
        let parameters = "tableName=" + tableName
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "m-query.php?");
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        let task = session.dataTask(with: request) { (data, response, error)  in
            if error != nil {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async {
                let objects = try! JSON(data: data!)
                var ok = false
                
                if objects.count != 0 {
                    // For
                    for i in 0..<objects.count {
                        let obj = objects[i]
                        if obj["ID_id"].string == id {
                            ok = true
                            completion(obj)
                        }
                        
                        // Object doesn't exists in database
                        if (i == objects.count-1 && !ok) { completion(nil) }
                    }// ./ For
                    
                // No Objects
                } else { completion(nil) }
                
            }// ./ Dispatch
        }; task.resume()
    }
    
      
    // ------------------------------------------------
    // MARK: - XSDelete -> DELETE AN OBJECT
    // ------------------------------------------------
    func XSDelete(tableName:String, id:String, completion: @escaping (_ success:Bool?, _ error:String?) -> Void) {
        let parameters = "tableName=\(tableName)&id=\(id)"
        
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "m-delete.php?");
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        let task = session.dataTask(with: request) { data, response, error in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(false, error!.localizedDescription) }
                return
            }
              
            if let response = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                print("XSDelete -> RESPONSE: " + response)
                
                DispatchQueue.main.async {
                    if response == "" { completion(false, E_203)
                    // Delete obj
                    } else { completion(true, nil) }// ./ If
                }
                
            // NO response
            } else { DispatchQueue.main.async { completion(false, XS_ERROR) } }// ./ If response
        }; task.resume()
    }
    
    
    
    
    // ------------------------------------------------
    // MARK: - XSQuery -> QUERY DATA
    // ------------------------------------------------
    func XSQuery(tableName:String, columnName:String, orderBy:String, completion: @escaping (_ objects:JSON?, _ error:String?) -> Void) {
        let parameters = "tableName=\(tableName)&columnName=\(columnName)&orderBy=\(orderBy)"
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "m-query.php?");
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        // request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = session.dataTask(with: request) { (data, response, error)  in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(false, error!.localizedDescription) }
                return
            }
            DispatchQueue.main.async {
                // Get data
                let objects = try! JSON(data: data!)
                completion(objects, nil)
            }
        }; task.resume()
    }
    
      
    // ------------------------------------------------
    // MARK: - MAKE QUERY PARAMETERS STRING
    // ------------------------------------------------
    func param(columnName:String, value:String) -> String {
        var p = ""
        p += "&" + columnName + "=" + value
    return p
    }
    
    
    
    // ------------------------------------------------
    // MARK: - XSRefreshObjectData -> REFRESH AN OBJECT'S DATA
    // ------------------------------------------------
    func XSRefreshObjectData(tableName:String, object:JSON, completion: @escaping (_ object:JSON?,  _ error:String?) -> Void) {
        let parameters = "tableName=\(tableName)"
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "m-query.php?");
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        let task = session.dataTask(with: request) { (data, response, error)  in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(false, error!.localizedDescription) }
                return
            }
            DispatchQueue.main.async {
                let objects = try! JSON(data: data!)
                for i in 0..<objects.count {
                    let obj = objects[i]
                    if obj["ID_id"].string == object["ID_id"].string! { completion(obj, nil) }
                }// ./ For
            }
        }; task.resume()
    }
    
      
      
    // ------------------------------------------------
    // MARK: - XSObject -> CREATE DATA
    // ------------------------------------------------
    func XSObject(_ parameters:[String: String], completion: @escaping (_ error:String?, _ object:JSON?) -> Void) {
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: TABLES_PATH + "m-add-edit.php?")
        var request = URLRequest(url:myUrl!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = parameters.percentEncoded()
        let task = session.dataTask(with: request) { data, response, error in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(error!.localizedDescription, nil) }
                return
            }
            if let response = String(data: data!, encoding: .utf8) {
                // print("XSObject -> RESPONSE: " + response + "\n-------------------")
                DispatchQueue.main.async {
                    let obj = JSON(parseJSON: response)
                    if response.contains("ID_id") { completion(nil, obj)
                    } else { completion(E_201, nil) }
                }
            // NO response
            } else { DispatchQueue.main.async { completion(XS_ERROR, nil) } } //./ If response
        }; task.resume()
    }
      
      
    
    // ------------------------------------------------
    // MARK: - XSUploadFile -> UPLOAD A FILE
    // ------------------------------------------------
    func XSUploadFile(fileData:Data, fileName:String , completion: @escaping (_ fileURL:String?, _ error:String?) -> Void) {
        print("FILENAME: \(fileName)")
          
        let boundary: String = "------VohpleBoundary4QuqLuM1cE5lMwCy"
        let contentType: String = "multipart/form-data; boundary=\(boundary)"
        let request = NSMutableURLRequest()
        request.url = URL(string: DATABASE_PATH + "upload-file.php")
        request.httpShouldHandleCookies = false
        request.timeoutInterval = 60
        request.httpMethod = "POST"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        let body = NSMutableData()
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition: form-data; name=\"fileName\"\r\n\r\n".data(using: String.Encoding.utf8)!)
        body.append("\(fileName)\r\n".data(using: String.Encoding.utf8)!)
          
        body.append("--\(boundary)\r\n".data(using: String.Encoding.utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"file\"\r\n".data(using: String.Encoding.utf8)!)
        
        // File is an image
        if fileName.hasSuffix(".jpg") {
            body.append("Content-Type:image/png\r\n\r\n".data(using: String.Encoding.utf8)!)
        // File is a video
        } else if fileName.hasSuffix(".mp4") {
            body.append("Content-Type:video/mp4\r\n\r\n".data(using: String.Encoding.utf8)!)
        }
        
        body.append(fileData)
        body.append("\r\n".data(using: String.Encoding.utf8)!)
          
          
        body.append("--\(boundary)--\r\n".data(using: String.Encoding.utf8)!)
        request.httpBody = body as Data
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(nil, error!.localizedDescription) }
                return
            }
            if let response = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                print("XSUploadFile -> RESPONSE: " + DATABASE_PATH + response)
                DispatchQueue.main.async { completion(DATABASE_PATH + response, nil) }
            
            // No response
            } else { DispatchQueue.main.async { completion(nil, E_401) } }// ./ If response
        }; task.resume()
    }
    
    
    
      
    // ------------------------------------------------
    // MARK: - XSiOSPush -> SEND iOS PUSH NOTIFICATION
    // ------------------------------------------------
    func XSSendiOSPush(message:String, deviceToken:String, pushType:String, completion: @escaping (_ success:Bool?, _ error:String?) -> Void) {
        let parameters = "message=\(message)&deviceToken=\(deviceToken)&pushType=\(pushType)"
              
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: DATABASE_PATH + "_Push/send-ios-push.php?")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        let task = session.dataTask(with: request) { data, response, error in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(false, error!.localizedDescription) }
                return
            }
              
            if let response = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                print("XSSendiOSPush -> RESPONSE: " + response)
                
                DispatchQueue.main.async {
                    if response == "e_104" { completion(false, E_104)
                    // Push sent!
                    } else { completion(true, nil) }// ./ If
                }
            // No response
            } else { DispatchQueue.main.async { completion(false, XS_ERROR) } }// ./ If response
        }; task.resume()
    }
    
    
    
    // ------------------------------------------------
    // MARK: - XSSendAndroidPush -> SEND ANDROID PUSH NOTIFICATION
    // ------------------------------------------------
    func XSSendAndroidPush(message:String, deviceToken:String, pushType:String, completion: @escaping (_ success:Bool?, _ error:String?) -> Void) {
        let parameters = "message=\(message)&deviceToken=\(deviceToken)&pushType=\(pushType)"
            
        let session = URLSession(configuration: .ephemeral)
        let myUrl = URL(string: DATABASE_PATH + "_Push/send-android-push.php?")
        var request = URLRequest(url:myUrl!)
        request.httpMethod = "POST"
        request.httpBody = parameters.data(using: .utf8)
        let task = session.dataTask(with: request) { data, response, error in
            guard let _:Data = data as Data?, let _:URLResponse = response, error == nil else {
                DispatchQueue.main.async { completion(false, error!.localizedDescription) }
                return
            }
            
            if let response = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) {
                print("XSSendAndroidPush -> RESPONSE: " + response)
                
                DispatchQueue.main.async {
                    if response == "e_104" { completion(false, E_104)
                    // Push sent!
                    } else { completion(true, nil) }// ./ If
                }
            // no response
            } else { DispatchQueue.main.async { completion(false, XS_ERROR) } }// ./ If response
        }; task.resume()
    }
    
    
    // ------------------------------------------------
    // MARK: - XSGetDateFromString -> GET DATE FROM STRING
    // ------------------------------------------------
    func XSGetDateFromString(_ dateStr:String) -> Date {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.autoupdatingCurrent
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let date = df.date(from: dateStr)
        return date!
    }
    
    // ------------------------------------------------
    // MARK: - XSGetStringFromDate -> GET STRING FROM DATE
    // ------------------------------------------------
    func XSGetStringFromDate(_ date:Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.autoupdatingCurrent
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let dateStr = df.string(from: date)
        return dateStr
    }
    
    
    // ------------------------------------------------
    // MARK: - XSGetArrayFromJSONArray -> GET ARRAY FROM JSON ARRAY
    // ------------------------------------------------
    func XSGetArrayFromJSONArray(_ arr:[JSON]) -> [String] {
        var array = [String]()
        for i in 0..<arr.count { array.append("\(arr[i])")}
    return array
    }
   
    
    // ------------------------------------------------
    // MARK: - XSGetStringFromArray -> GET STRING FROM ARRAY
    // ------------------------------------------------
    func XSGetStringFromArray(_ arr:[String]) -> String {
        let arrayStr = arr.joined(separator: ",")
    return arrayStr
    }
    
    
    // ------------------------------------------------
    // MARK: - GET LOCATION FROM GPS ARRAY
    // ------------------------------------------------
    func XSGetLocationFromGPSArray(_ arr:[JSON]) -> CLLocation {
        var loc = CLLocation()
        var array = [CLLocationDegrees]()
        for i in 0..<arr.count {
            let coord = Double("\(arr[i])")
            array.append(CLLocationDegrees(floatLiteral: coord!))
        }
        loc = CLLocation(latitude: array[0], longitude: array[1])
    return loc
    }
    
    
    // ------------------------------------------------
    // MARK: - GET STRING FROM LOCATION
    // ------------------------------------------------
    func XSGetStringFromLocation(_ location:CLLocation) -> String {
        return String(location.coordinate.latitude) + "," + String(location.coordinate.longitude)
    }
    
    
    // --------------------------------------------------------
    // MARK: - XSGetImageFromURL -> GET AN IMAGE FROM A URL
    // --------------------------------------------------------
    func XSGetImageFromURL(_ url: String, completionHandler: @escaping (_ image: UIImage?) -> ()) {
        let imgURL = URL(string: url)
        let dataTask = URLSession.shared.dataTask(with: imgURL!) { (data, response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    print("Error fetching the image! 😢")
                    completionHandler(nil)
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(UIImage(data: data!)!)
                }
            }
        }
        dataTask.resume()
    }
    
    
}// ./ extension: ViewController


// ------------------------------------------------
// ------------------------------------------------
// MARK: - UTILITY EXTENSIONS FOR XServer
// ------------------------------------------------
// ------------------------------------------------
extension Dictionary {
    func percentEncoded() -> Data? {
        return map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="

        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}


// ------------------------------------------------
// MARK: - XSRemoveDuplicatesFromArray -> REMOVE DUPLICATES FORM ARRAY
// ------------------------------------------------
extension Array where Element: Equatable {
    mutating func XSRemoveDuplicatesFromArray() {
        var result = [Element]()
        for value in self {
            if !result.contains(value) {
                result.append(value)
            }
        }
        self = result
    }
}


// ------------------------------------------------
// MARK: - GET IMAGE FROM LINK
// ------------------------------------------------
extension UIImageView {
    func downloaded(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() {
                self.image = image
            }
            }.resume()
    }
    func getImage(from link: String) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url)
    }
}
