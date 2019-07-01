//
//  main.swift
//  Shangri-La iOS Forensic Toolkit
//
//  Created by エス on 19/06/2019.
//  Copyright © 2019 エス. All rights reserved.
//

import Foundation
import Shout
import Cocoa


//TODO: 6.App decrypting WIP  8. Backup WIP

// Example usage:

fileprivate func directoryExistsAtPath(_ path: String) -> Bool {
    var isDirectory = ObjCBool(true)
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}


func shell(_ command: String) -> String {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
    return output
}



func clear(){
    print("\(shell("clear")) ")
}



var file = NSURL.init(fileURLWithPath: "./keys.txt")

func readPass(silent: Bool) -> String? {
    return silent ? String(cString: getpass("")) : readLine()
}


func macconf(){
    var homeFolder = shell("cd ~ && pwd")
    homeFolder.removeLast()
    print("\n Program will now chceck if libimobiledevice, usbmuxd and ideviceinstaller are installed and will install it if not.")
    print("\n Also ~/.ShangrilaSupportFiles folder will be created for storing tsschecker(s0uthwest ver), keychain_dumper_nosegfault and other binaries, that might be needed later.")
    print("\n Write \"OKAY\" and press enter to confirm.")
    let confirmation = readLine()!
    if (confirmation == "OKAY"){
        _ = print("\(shell("brew install libimobiledevice usbmuxd ideviceinstaller"))")
        _ = print("\(shell("mkdir \(homeFolder)/.ShangrilaSupportFiles ; wget -P \(homeFolder)/.ShangrilaSupportFiles/ -q -o /dev/null https://github.com/vocaeq/keychain-Dumper-Nosegfault/raw/master/keychain_dumper"))")
        _ = print("\(shell("wget -P \(homeFolder)/.ShangrilaSupportFiles/ -q -o /dev/null https://raw.githubusercontent.com/vocaeq/keychain-Dumper-Nosegfault/master/entitlements.xml"))")
        _ = print("\(shell("wget -P \(homeFolder)/.ShangrilaSupportFiles/ -q -o /dev/null https://github.com/s0uthwest/tsschecker/releases/download/355/tsschecker_macOS_v355.zip"))")
        _ = print("\(shell("cd \(homeFolder)/.ShangrilaSupportFiles/ ; unzip -a ./tsschecker_macOS_v355.zip"))")
        _ = print("\(shell("rm -rf \(homeFolder)/.ShangrilaSupportFiles/tsschecker_macOS_v355.zip"))")}
    else{
        exit(0)
    }
    
}

func configure(ssh: SSH, config: String){
    do{
        if (config == "0" || config == ""){
            print("Going back")
            sleep(1)
        }else if (config == "1"){
            var homeFolder = shell("cd ~ && pwd")
            homeFolder.removeLast()
            file = NSURL.init(fileURLWithPath: "\(homeFolder)/.ShangrilaSupportFiles/keychain_dumper")
            //print(try String(contentsOf: file as URL))
            let sftp = try ssh.openSftp()
            try sftp.upload(localURL: file as URL, remotePath: "/usr/bin/keychain_dumper")
            file = NSURL.init(fileURLWithPath: "\(homeFolder)/.ShangrilaSupportFiles/entitlements.xml")
            try sftp.upload(localURL: file as URL, remotePath: "/usr/bin/ent.xml")
            try ssh.execute("cd /usr/bin/ && ldid -Sent.xml ./keychain_dumper && chmod +x ./keychain_dumper")
        }else if (config == "2"){
            macconf()
        }
        
        
    }catch{
        print("Something went wrong")
    }
    
}

//MARK: SSH connections

func USBSSH(isdummy: Bool? = false) -> Any{
    if (isdummy == true){
        return false;
    }
    do {
        
        let ip = "localhost"
        clear()
        
        print("Provide password, leave if default -> ")
        var password = String(cString: getpass(""))
        while password == "" {
            print("Using alpine as password")
            password = "alpine";
        }
        let ssh = try SSH(host: ip, port: 2222)
        try ssh.authenticate(username: "root", password: password );
        return ssh;
    } catch {
        print("Couldn't connect, chceck your password")
        sleep(1)
        return false;
    }
}


func returnSSH(isdummy: Bool? = false) -> Any{
    if (isdummy == true){
        return false;
    }
    do {
        clear()
        print("Provide ip -> ")
        var ip = readLine()
        while ip == "" {
            print("Provide correct ip ->")
            ip = readLine();
        }
        
        print("Provide password -> ")
        var password = String(cString: getpass(""))
        while password == "" {
            print("Using alpine as password")
            password = "alpine";
        }
        
        let ssh = try SSH(host: ip!)
        try ssh.authenticate(username: "root", password: password)
        return ssh;
    } catch {
        print("Couldn't connect, chceck ip and password")
        sleep(1)
        return false;
    }
}

//MARK: Main function

func choice (selection: String , ssh: SSH) {
    do{
        if (selection == "0"){
            print("Cofigure: iPhone (1), Mac (2), both (3)");
            let config = readLine()
            if (config == "3") {
                configure(ssh: ssh, config: "1");
                configure(ssh: ssh, config: "2");
            }else{
                configure(ssh: ssh, config: config ?? "0");
            }
            
        }else if (selection == "1"){
            print("\(shell("clear")) ")
            print("-> Device name: \(shell("ideviceinfo -k DeviceName") )")
            print("-> Device type: \(shell("ideviceinfo -k ProductType") )")
            print("-> Hardware model: \(shell("ideviceinfo -k HardwareModel") )")
            print("-> System version: \(shell("ideviceinfo -k ProductVersion") )")
            print("-> Build version: \(shell("ideviceinfo -k BuildVersion") )")
            print("-> Serial Number: \(shell("ideviceinfo -k SerialNumber") )")
            print("-> UDID: \(shell("ideviceinfo -k UniqueDeviceID") )")
            print("Do you want to save installed app list? (1). Yes  (2). No")
            let applist = readLine()
            if( applist == "1"){
                _ = print(shell("ideviceinstaller -l -o list_user > applist.txt"))
            }
            print("Press enter to go back")
            _ = readLine()
            
            
            
        }else if (selection == "2") {
            try ssh.execute("keychain_dumper > keys")
            let sftp = try ssh.openSftp()
            file = NSURL.init(fileURLWithPath: "./keys.txt")
            try sftp.download(remotePath: "/private/var/root/keys", localURL: file as URL);
        }else if (selection == "9"){
            _ = shell("pkill iproxy")
            exit(0)
            
        }else if( selection == "8"){
            var homeFolder = shell("cd ~ && pwd")
            homeFolder.removeLast()
            var productversion = shell("ideviceinfo -k ProductVersion")
            productversion.removeLast()
            var udid = shell("ideviceinfo -k UniqueDeviceID")
            udid.removeLast()
            var eicd = shell("ideviceinfo -k UniqueChipID")
            eicd.removeLast()
            var device = shell("ideviceinfo -k ProductType")
            device.removeLast()
            print("Entering recovery... please, wait...")
            _ = shell("ideviceenterrecovery \(udid)")
            sleep(12)
            print("Getting apnonce...")
            var nonce = shell("irecovery -q | grep NONC | cut -d ' ' -f 2")
            nonce.removeLast()
            print("Your apnonce: \(nonce)")
            _ = shell("irecovery -n")
            print("Restarting device... ")
            sleep(3)
            print("Do you want to save blobs for (1)specific or ( )latest version ?")
            let choice = readLine()
            switch choice {
            case "1":
                print("Provide signed version: ")
                let version = readLine()!
                _ = shell("\(homeFolder)/.ShangrilaSupportFiles/tsschecker -d \(device) -e \(eicd) --apnonce \(nonce) -i \(version) -s --save-path ./")
            default:
                print("Getting blobs for latest version...")
                _ = shell("\(homeFolder)/.ShangrilaSupportFiles/tsschecker -d \(device) -e \(eicd) --apnonce \(nonce) -l -s --save-path ./")
                print("Done, please re-jailbreak your device and run this program again.")
                print("Remember to copy your blob to safe place.")
                _ = readLine()
                _ = shell("pkill iproxy")
                exit(0)
            }
            
        }else if (selection == "3"){
            print("Obtaining whole user data is time consuming, please be patient...\n")
            print("Also, make sure that your're device can connect via RSA public key with your PC.\nI'm working on it.")
            _ = shell("ssh root@localhost -p 2222 'tar -cf - /private/var/' > user.tar")
            print("\n\nPress enter to go back.")
            _ = readLine()
            
        }else if (selection == "4"){
            
            print("Obtaining Media folder may be time consuming, please be patient...")
            
            print("Also, make sure that your're device can connect via RSA public key with your PC.\nI'm working on it.")
            _ = shell("ssh root@localhost -p 2222 'tar -cf - /private/var/mobile/Media/' > Media.tar")
            print("\n\nPress enter to go back.")
            _ = readLine()
        }else if (selection == "5"){
            /*var (_, myip) = try ssh.capture("ipconfig getifaddr en0")
             print("\(myip)")
             if (myip == ""){
             myip = "localhost"
             }*/
            print("Obtaining Logs, please be patient...")
            print("Also, make sure that your're device can connect via RSA public key with your PC.\nI'm working on it.")
            _ = shell("ssh root@localhost -p 2222 'tar -cf - /private/var/mobile/Library/Logs/CrashReporter/' > Logs.tar")
            print("\n\nPress enter to go back.")
            _ = readLine()
        }else if (selection == "6"){
            let sftp = try ssh.openSftp()
            let file = NSURL.init(fileURLWithPath: "./sms.db")
            _ = try sftp.download(remotePath: "/var/mobile/Library/SMS/sms.db", localURL: file as URL)
            print("Completed. See sms.db in your current folder.")
            _ = readLine()
        }
    }catch{
        print("couldn:")
    }
}











//MARK: Start

print("\(shell("clear")) ")

let myfilemanager = FileManager.default
var isDirectory:ObjCBool = true
var homeFolder = shell("cd ~/ && pwd")
homeFolder.removeLast()
let path = "\(homeFolder)/.ShangrilaSupportFiles/tsschecker"
let justpassingby: Bool = myfilemanager.fileExists(atPath: path)

if (!justpassingby) {
    print("Seems like you're running this toolkit for the first time, let me help you with configuration");
    sleep(2)
    macconf()
}





print("Do you want to connect by USB (2) or SSH (1)?")
print("Mac configuration (0)")
var pid = ""
var myselection: String? =  "2";
var ssh = returnSSH(isdummy: true);


while( "\(type(of: ssh))" != "SSH"){
    if(myselection == "1"){
        while ("\(type(of: ssh))" == "Bool" && myselection == "1") {
            clear()
            print("-> Connecting via WiFi. \n-> (0). Change connection type \n-> (1). Configure Mac  \n-> ( ). Connect")
            let change = readLine()
            if (change != "0" && change != "1"){
                ssh = returnSSH()
            }else if(change == "0"){
                myselection = "2"
            }else if(change == "1"){
                macconf()
            }
            
        }
    }else if(myselection == "2"){
        let dispatchQueue = DispatchQueue(label: "QueueIdentification", qos: .background)
        dispatchQueue.async{
            _ = shell("iproxy 2222 22 >/dev/null 2>&1")
        }
        while ("\(type(of: ssh))" == "Bool" && myselection == "2") {
            clear()
            print("-> Connecting via USB. \n-> (0). Change connection type \n-> (1). Configure Mac  \n-> ( ). Connect")
            let change = readLine()
            if (change != "0" && change != "1"){
                ssh = USBSSH()
            }else if(change == "0"){
                myselection = "1"
            }else if(change == "1"){
                macconf()
            }
            
        }}
    
}


print("connected succesfully")
sleep(1)






while (true) {
    clear()
    print(" ")
    print("-> Shangri-La iOS Forensic Toolkit")
    print("-> Created by エス on 2019/7/1.")
    print("-> 0. Configure devices ")
    print("-> 1. Device info")
    print("-> 2. Dump keychain (screen must be on)")
    print("-> 3. Copy whole user data (/private/var/) (USB Only)")
    print("-> 4. Copy Media (USB Only)")
    print("-> 5. Copy Logs (USB Only)")
    print("-> 6. Copy sms database")
    print("-> 8. Save SHSH2 blobs (works on A12)")
    print("-> 9. Exit (kills iproxy if USB connection is running)")
    myselection =  readLine();
    while myselection == ""{
        print("What's your choice:")
        myselection =  readLine();
    }
    choice(selection: myselection ?? "0", ssh: ssh as! SSH)
    
}




exit(0);
