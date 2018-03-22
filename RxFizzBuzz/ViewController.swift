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

class ViewController: UIViewController {
    
    @IBOutlet weak var fizzBuzz: UILabel!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var fizz: UILabel!
    @IBOutlet weak var buzz: UILabel!
    @IBOutlet weak var minus1: UIButton!
    @IBOutlet weak var minus5: UIButton!
    @IBOutlet weak var plus5: UIButton!
    @IBOutlet weak var plus1: UIButton!
    let fizzTrigger = BehaviorSubject<Bool>(value: true)
    let buzzTrigger = BehaviorSubject<Bool>(value: true)
    let fizzBuzzTrigger = BehaviorSubject<Bool>(value: true)
    
    let bag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        fizzTrigger.bind(to: fizz.rx.isHidden).disposed(by: bag)
        buzzTrigger.bind(to: buzz.rx.isHidden).disposed(by: bag)
        fizzBuzzTrigger.bind(to: fizzBuzz.rx.isHidden).disposed(by: bag)
        
        let counterObservable = Observable<Int>
            .interval(1.0, scheduler: MainScheduler.instance)
            .map{ _ in 1}
            .startWith(0)

        let plusOneObservable = plus1.rx.tap.map { _ in 1}
        let plusFiveObservable = plus5.rx.tap.map { _ in 5}
        let minusOneObservable = minus1.rx.tap.map { _ in -1}
        let minusFiveObservable = minus5.rx.tap.map { _ in -5}
        
        let numberObservable = Observable
            .merge(plusOneObservable,
                   plusFiveObservable,
                   minusOneObservable,
                   minusFiveObservable,
                   counterObservable)
            .scan(0, accumulator: {$0 + $1})

        numberObservable.map { String($0)}.bind(to: number.rx.text).disposed(by: bag)
        
        numberObservable
            .skipWhile{ $0 == 0}
            .map { $0 % 3 == 0 && $0 % 15 != 0 }
            .distinctUntilChanged()
            .debug("fizz")
            .subscribe(onNext: { [weak self] bool in
                self?.fizzTrigger.onNext(!bool)
            }).disposed(by: bag)
        
        numberObservable
            .skipWhile{$0 == 0}
            .map { $0 % 5 == 0 && $0 % 15 != 0}
            .distinctUntilChanged()
            .debug("buzz")
            .subscribe(onNext: { [weak self] bool in
                self?.buzzTrigger.onNext(!bool)
            }).disposed(by: bag)
        
        numberObservable
            .skipWhile{$0 == 0}
            .map { $0 % 15 == 0 }
            .distinctUntilChanged()
            .debug("fizzbuzz")
            .subscribe(onNext: { [weak self] bool in
                self?.fizzBuzzTrigger.onNext(!bool)
            }).disposed(by: bag)
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

