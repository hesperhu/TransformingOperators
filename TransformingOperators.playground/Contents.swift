//https://github.com/kodecocodes/comb-materials/blob/editions/3.0/03-transforming-operators/projects/Final.playground/Contents.swift
//https://github.com/kodecocodes/comb-materials/blob/editions/3.0/03-transforming-operators/projects/challenge/Final.playground/Contents.swift

import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

//将数据的处理分成几段，每段当做一个operator，最后再sink处理 2023-03-06(Mon) 10:13:28
//根据final结果做了优化 2023-03-06(Mon) 10:24:33
example(of: "Create a phone number lookup") {
  let contacts = [
    "603-555-1234": "Florent",
    "408-555-4321": "Marin",
    "217-555-1212": "Scott",
    "212-555-3434": "Shai"
  ]
  
  func convert(phoneNumber: String) -> Int? {
    if let number = Int(phoneNumber),
      number < 10 {
      return number
    }

    let keyMap: [String: Int] = [
      "abc": 2, "def": 3, "ghi": 4,
      "jkl": 5, "mno": 6, "pqrs": 7,
      "tuv": 8, "wxyz": 9
    ]

    let converted = keyMap
      .filter { $0.key.contains(phoneNumber.lowercased()) }
      .map { $0.value }
      .first
    return converted
  }

  func format(digits: [Int]) -> String {
    var phone = digits.map(String.init)
                      .joined()

    phone.insert("-", at: phone.index(
      phone.startIndex,
      offsetBy: 3)
    )

    phone.insert("-", at: phone.index(
      phone.startIndex,
      offsetBy: 7)
    )

    return phone
  }

  func dial(phoneNumber: String) -> String {
    guard let contact = contacts[phoneNumber] else {
      return "Contact not found for \(phoneNumber)"
    }

    return "Dialing \(contact) (\(phoneNumber))..."
  }
  
  let input = PassthroughSubject<String, Never>()
  
    input
        .map({ dial in
            convert(phoneNumber: dial)
        })
        .replaceNil(with: 0)
        .collect(10)
        .map { digits in
            format(digits: digits)
        }
        .sink { numberStr in
            print("first dial",dial(phoneNumber: numberStr))
        }
        .store(in: &subscriptions)
   
    input
        .map(convert)
        .replaceNil(with: 0)
        .collect(10)
        .map(format)
        .map(dial)
        .sink{print("second dial:",$0)}
        .store(in: &subscriptions)

  "0!1234567".forEach {
    input.send(String($0))
  }
  
  "4085554321".forEach {
    input.send(String($0))
  }
  
  "A1BJKLDGEH".forEach {
    input.send("\($0)")
  }
    
    input.send(completion: .finished)
}
/*
 
 ——— Example of: Create a phone number lookup ———
 first dial Contact not found for 000-123-4567
 second dial: Contact not found for 000-123-4567
 first dial Dialing Marin (408-555-4321)...
 second dial: Dialing Marin (408-555-4321)...
 first dial Dialing Shai (212-555-3434)...
 second dial: Dialing Shai (212-555-3434)...

 */

//对队列中的数据进行处理，数据结果会在下一次处理时带入 2023-03-06(Mon) 08:57:51
example(of: "scan")
{
    var dailyGainLoss: Int {
        .random(in: 0...20)
    }
    
    let thisMonth = (0...5)
        .publisher
        .map { _ in
            dailyGainLoss
        }
        .scan(-2) { last, current in
            print("上次数值：\(last), 本次输入：\(current)")
            return max(0, last + current)
        }
        .sink { value in
            print("sink中的数值：\(value)")
        }
        .store(in: &subscriptions)
}
/*
 ——— Example of: scan ———
 上次数值：-2, 本次输入：20
 上次数值：18, 本次输入：10
 上次数值：28, 本次输入：5
 上次数值：33, 本次输入：3
 上次数值：36, 本次输入：9
 上次数值：45, 本次输入：4
 sink中的数值：18
 sink中的数值：28
 sink中的数值：33
 sink中的数值：36
 sink中的数值：45
 sink中的数值：49
 */

//如果队列中没有值，那么在结束之前，可以人为的发送一个消息进行补充 2023-03-05(Sun) 21:07:47
example(of: "replaceEmptyWith") {
    let empty = Empty<Int, Never>()
    
    empty
        .replaceEmpty(with: 1)
        .sink { failure in
            print(failure)
        } receiveValue: { value in
            print(value)
        }
        .store(in: &subscriptions)
}
/*
 ——— Example of: replaceEmptyWith ———
 1
 finished
 */

//消除队列中的optional值 2023-03-05(Sun) 21:06:59
example(of: "replaceNil") {
    [Optional("A"), nil, "加"].publisher
        .eraseToAnyPublisher()
        .replaceNil(with: "-")
        .collect()
        .sink { value in
            print(value)
        }
        .store(in: &subscriptions)
}
/*
 ——— Example of: replaceNil ———
 ["A", "-", "加"]
 */

//使用映射型处理逻辑，先对消息做扁平化处理，再对消息进行个性化处理 2023-03-14(Tue) 21:14:12 
//https://www.donnywals.com/using-map-flatmap-and-compactmap-in-combine/
example(of: "flatMap") {
    func decode(_ codes: [Int]) -> AnyPublisher<String, Never> {
        Just(
            codes
                .compactMap{ code in
                guard (32...255).contains(code) else {return nil}
                return String(UnicodeScalar(code) ?? " ")
                }
                .joined()
        )
        .eraseToAnyPublisher()
    }
    
    [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33]
        .publisher
        .collect(7)
        .flatMap(decode)
        .sink { value in
            print(value)
        }
        .store(in: &subscriptions)
    
}
/*
 ——— Example of: flatMap ———
 Hello,
 World!
 */

//在处理数据流的过程中，使用try类型的operator，可以把error往后传递 2023-03-05(Sun) 17:05:55
example(of: "tryMap") {
    Just("File path of nowhere")
        .tryMap { value in
            try FileManager.default.contentsOfDirectory(atPath: value)
        }
        .sink { completion in
            print("Error received in sink:")
            print(completion)
        } receiveValue: { value in
            print(value)
        }
        .store(in: &subscriptions)
}
/*
 ——— Example of: tryMap ———
 Error received in sink:
 failure(Error Domain=NSCocoaErrorDomain Code=260 "The folder “File path of nowhere” doesn’t exist." UserInfo={NSUserStringVariant=(
     Folder
 ), NSFilePath=File path of nowhere, NSUnderlyingError=0x600002370690 {Error Domain=NSPOSIXErrorDomain Code=2 "No such file or directory"}})
 */


//使用映射型的operator对对象的属性进行深入的处理 2023-03-05(Sun) 16:18:29
example(of: "Mapping key paths") {
    let publisher = PassthroughSubject<Coordinate, Never>()
    
    publisher
        .map(\.x, \.y)
        .sink { x, y in
            print("坐标(\(x),\(y))在四象限的位置:\(quadrantOf(x: x, y: y))")
        }
        .store(in: &subscriptions)
    
    publisher.send(Coordinate(x: 45, y: 9))
    publisher.send(Coordinate(x: -45, y: 9))
    publisher.send(Coordinate(x: 0, y: 9))
    publisher.send(Coordinate(x: 0, y: 0))
    publisher.send(Coordinate(x: -1, y: -1))
}
/*
 ——— Example of: Mapping key paths ———
 坐标(45,9)在四象限的位置:1
 坐标(-45,9)在四象限的位置:2
 坐标(0,9)在四象限的位置:boundary
 坐标(0,0)在四象限的位置:boundary
 坐标(-1,-1)在四象限的位置:3*/

//使用映射型operator对每个数据进行逐一的处理 2023-03-05(Sun) 16:04:00
example(of: "map") {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    
    [234, 89, 1090].publisher
        .map { value in
            formatter.string(for: NSNumber(integerLiteral: value)) ?? ""
        }
        .sink { value in
            print("Received value in sink: \(value)")
        }
        .store(in: &subscriptions)
}
/*
 ——— Example of: map ———
 Received value in sink: two hundred thirty-four
 Received value in sink: eighty-nine
 Received value in sink: one thousand ninety
*/

//使用缓存类operator来缓存队列数据 2023-03-05(Sun) 15:51:05
example(of: "Collect") {
    ["甲","乙","丙","丁","戊己庚辛","金木水火","乾坤"].publisher
        .collect(3)
        .sink { completion in
            print("Completion in sink: \(completion)")
        } receiveValue: { value in
            print("Value in sink: \(value)")
            value.publisher
                .sink { string in
                    print("--value in array: \(string)")
                }
        }
        .store(in: &subscriptions)
}
/*
 ——— Example of: Collect ———
 Value in sink: ["甲", "乙", "丙"]
 --value in array: 甲
 --value in array: 乙
 --value in array: 丙
 Value in sink: ["丁", "戊己庚辛", "金木水火"]
 --value in array: 丁
 --value in array: 戊己庚辛
 --value in array: 金木水火
 Value in sink: ["乾坤"]
 --value in array: 乾坤
 Completion in sink: finished*/

/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.
