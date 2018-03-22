//
//  ViewController.swift
//  RxFizzBuzz
//
//  Created by 原野誉大 on 2018/03/21.
//  Copyright © 2018年 原野誉大. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum Type: String {
    case Fizz = "Fizz"
    case Buzz = "Buzz"
    case FizzBuzz = "FizzBuzz"
    case Other = "Other"
    static func ==(lhs: Type, rhs: Type) -> Bool {
        switch (lhs, rhs) {
        case (.Fizz, .Fizz), (.Buzz, .Buzz), (.FizzBuzz, .FizzBuzz), (.Other, .Other):
            return true
        default:
            return false
        }
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var fizzBuzz: UILabel!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var fizz: UILabel!
    @IBOutlet weak var buzz: UILabel!
    @IBOutlet weak var minus1: UIButton!
    @IBOutlet weak var minus5: UIButton!
    @IBOutlet weak var plus5: UIButton!
    @IBOutlet weak var plus1: UIButton!
    @IBOutlet weak var fizzButton: UIButton!
    @IBOutlet weak var buzzButton: UIButton!
    @IBOutlet weak var fizzBuzzButton: UIButton!
    @IBOutlet weak var answer: UILabel!
    @IBOutlet weak var result: UILabel!
    let publishAnswer = PublishSubject<String>()
    
    let bag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // 一定時間ごとに数値を流す
        
        let counterObservable = Observable<Int>
            .interval(3.0, scheduler: MainScheduler.instance)
            .map{ _ in 1}
            .startWith(0)
            .share()
        
        let plusOneObservable = plus1.rx.tap.map { _ in 1}
        let plusFiveObservable = plus5.rx.tap.map { _ in 5}
        let minusOneObservable = minus1.rx.tap.map { _ in -1}
        let minusFiveObservable = minus5.rx.tap.map { _ in -5}
        
        // 画面に表示されるカウント
        let numberObservable = Observable
            .merge(plusOneObservable,
                   plusFiveObservable,
                   minusOneObservable,
                   minusFiveObservable,
                   counterObservable)
            .scan(0, accumulator: {$0 + $1})
        
        
        // Fizzが表示されるタイミング
        
        let fizzObservable = numberObservable
            .skipWhile{ $0 == 0}
            .map { $0 % 3 == 0 && $0 % 15 != 0 }
            .startWith(false)
            .share()
        let buzzObservable = numberObservable
            .skipWhile{$0 == 0}
            .map { $0 % 5 == 0 && $0 % 15 != 0}
            .startWith(false)
            .share()
        let fizzBuzzObservable = numberObservable
            .skipWhile{$0 == 0}
            .map { $0 % 15 == 0 }
            .startWith(false)
            .share()
        
        let collectObservable: Observable<Type> = numberObservable.map{
            if $0 % 3 == 0 && $0 % 15 != 0 {
                return .Fizz
            } else if $0 % 5 == 0 && $0 % 15 != 0 {
                return .Buzz
            } else if $0 % 15 == 0{
                return .FizzBuzz
            } else {
                return .Other
            }
        }
        
        let answerObservable = Observable<Type>
            .merge(
                fizzButton.rx.tap.map { _ in Type.Fizz },
                buzzButton.rx.tap.map { _ in Type.Buzz},
                fizzBuzzButton.rx.tap.map { _ in Type.FizzBuzz }
            )
            .sample(counterObservable)
            .buffer(timeSpan: 3.0, count: 1, scheduler: MainScheduler.instance)
            .map{ $0.count == 1 ? $0[0] : Type.Other }

        let resultObservable = Observable<Bool>
            .zip(collectObservable, answerObservable) { correct, answer in
                return correct == answer
        }.debug("result")
        
        fizzObservable
            .map { !$0 }
            .bind(to: fizz.rx.isHidden)
            .disposed(by: bag)
        buzzObservable
            .map { !$0 }
            .bind(to: buzz.rx.isHidden)
            .disposed(by: bag)
        fizzBuzzObservable
            .map { !$0 }
            .bind(to: fizzBuzz.rx.isHidden)
            .disposed(by: bag)
        numberObservable
            .map { String($0)}
            .bind(to: number.rx.text)
            .disposed(by: bag)
        answerObservable
            .map {$0.rawValue}
            .bind(to: answer.rx.text)
            .disposed(by: bag)
        resultObservable
            .map { $0 ? "Correct!!": "Wrong" }
            .startWith("")
            .bind(to: result.rx.text)
            .disposed(by: bag)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

