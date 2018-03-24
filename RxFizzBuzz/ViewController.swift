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

    @IBOutlet weak var point: UILabel!
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
    @IBOutlet weak var start: UIButton!
    @IBOutlet weak var result: UILabel!
    let publishAnswer = PublishSubject<String>()

    let bag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let interval = 2.0

        // 一定時間ごとのカウンター
        let originalTimerObservable = Observable<Int>
            .interval(interval, scheduler: MainScheduler.instance)
            .skipUntil(start.rx.tap)
            .share()

        let counterObservable = originalTimerObservable
            .map{ _ in 1}
            .startWith(0)
            .share()

        // ボタンがタップされるごとのシーケンス

        let plusOneObservable = plus1.rx.tap.map { _ in 1}
        let plusFiveObservable = plus5.rx.tap.map { _ in 5}
        let minusOneObservable = minus1.rx.tap.map { _ in -1}
        let minusFiveObservable = minus5.rx.tap.map { _ in -5}

        // 画面に表示されるシーケンス
        let numberObservable = Observable
            .merge(plusOneObservable,
                   plusFiveObservable,
                   minusOneObservable,
                   minusFiveObservable,
                   counterObservable)
            .scan(0, accumulator: {$0 + $1})
        .share()


        // Fizz/Buzz/FizzBuzzの発生するシーケンス


        // 正解のシーケンス
        let correctSubject = PublishSubject<Observable<Type>>()
        let correctObservable = correctSubject.switchLatest().share()
        
        
        let level1CorrectObservable: Observable<Type> = numberObservable.debug("level1").map{
            if $0 % 3 == 0 && $0 % 15 != 0 {
                return .Fizz
            } else if $0 % 5 == 0 && $0 % 15 != 0 {
                return .Buzz
            } else if $0 % 15 == 0{
                return .FizzBuzz
            } else {
                return .Other
            }
        }.share()
        let level2CollectObservable: Observable<Type> = numberObservable.map{
            if $0 % 3 == 0 && $0 % 15 != 0 {
                return .Buzz
            } else if $0 % 5 == 0 && $0 % 15 != 0 {
                return .Fizz
            } else if $0 % 15 == 0{
                return .FizzBuzz
            } else {
                return .Other
            }
        }.share()
        let fizzObservable = correctObservable
            .map{ type -> Bool in
            if type == .Fizz {
                return true
            } else {
                return false
            }
        }.startWith(false)
        
        let buzzObservable = correctObservable
            .map{ type -> Bool in
                if type == .Buzz {
                    return true
                } else {
                    return false
                }
            }.startWith(false)
        let fizzBuzzObservable = correctObservable
            .map{ type -> Bool in
                if type == .FizzBuzz {
                    return true
                } else {
                    return false
                }
            }.startWith(false)

        // ユーザーが入力したFizzBuzz状態のシーケンス
        let answerObservable = Observable<Type>
            .merge(
                fizzButton.rx.tap.map { _ in Type.Fizz },
                buzzButton.rx.tap.map { _ in Type.Buzz},
                fizzBuzzButton.rx.tap.map { _ in Type.FizzBuzz }
            )
            .sample(originalTimerObservable)
            .buffer(timeSpan: interval, count: 1, scheduler: MainScheduler.instance)
            .map{ $0.count == 1 ? $0[0] : Type.Other }
            .share()

        // ユーザーの正当のシーケンス
        let resultObservable = Observable<Bool>
            .zip(correctObservable, answerObservable) { correct, answer in
                return correct == answer
        }
            .skipUntil(start.rx.tap)
            .share()

        // 現在のユーザーポイントのシーケンス
        let pointObservable = resultObservable
            .map { $0 ? 1: -1}
            .scan(0) {
                $0 + $1
        }
        
        // レベルアップイベント
        let levelChangeObservable = pointObservable.map { (point) -> Bool in
            if point >= 10 {
                return true
            } else {
                return false
            }
        }.distinctUntilChanged().startWith(false)
        

        // 以下画面とのバインド
        levelChangeObservable.skipWhile{$0 == false}
            .subscribe(onNext: {
                if $0 {
                    correctSubject.onNext(level2CollectObservable)
                } else {
                    correctSubject.onNext(level1CorrectObservable)
                }
            }).disposed(by: bag)
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
        resultObservable
            .subscribe(onNext: { [weak self] result in
                if result {
                    self?.result.textColor = UIColor.red
                } else {
                    self?.result.textColor = UIColor.blue
                }
        })
            .disposed(by: bag)

        pointObservable
            .map { String($0) }
            .bind(to: point.rx.text)
            .disposed(by: bag)
        
        start.rx.tap.subscribe(onNext: {
           correctSubject.onNext(level1CorrectObservable)
        }).disposed(by: bag)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

