import Foundation
import Combine

var subscriptions = Set<AnyCancellable>()

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
